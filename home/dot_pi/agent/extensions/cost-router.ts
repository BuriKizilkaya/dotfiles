import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { Message } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  ModelRoute,
  ModelRouteRequest,
} from "@earendil-works/pi-coding-agent";

const execFileAsync = promisify(execFile);
const THINKING_LEVELS = ["low", "medium", "high"] as const;
const COMPLEXITY_THRESHOLD = 3;
const DEBUG = process.env.COST_ROUTER_DEBUG === "1";

const COMPLEX_TASK = /\b(design|migration|migrate|refactor|projektweit|cross[- ]cutting|mehrere dateien|root cause|race condition|concurrency|parallelism|performance|profil(?:e|ing)|komplex|schwierig|debug(?:ging)?|fehleranalyse|teststrategie)\b/i;
const STRONG_TASK = /\b(architecture|architektur|security|sicherheit|threat model)\b/i;
const SIMPLE_TASK = /\b(rename|umbenennen|format(?:ieren)?|typo|rechtschreibung|erklär(?:e|en)|explain|kurz|one[- ]liner)\b/i;
const CODE_REVIEW_TASK = /\b(code review|review|prüf(?:e|en)|audit)\b/i;
const FILE_REFERENCE = /(?:[\w./-]+\.(?:[a-z]{1,8}))/gi;
const LIST_ITEM = /^\s*(?:\d+[.)]|[-*])\s+/gm;
const OVERRIDE = /^\s*!(cheap|normal|strong|auto)\b\s*/i;

export const MODEL_TIERS = {
  "github-copilot": { cheap: "gpt-6-luna", normal: "gpt-5.6-terra", strong: "gpt-6-sol" },
  "openai-codex": { cheap: "gpt-6-luna", normal: "gpt-5.6-terra", strong: "gpt-6-astra" },
} as const;

const MODEL_ALLOWLIST: Record<string, readonly string[]> = {
  "github-copilot": ["gpt-6-luna", "gpt-5.6-luna", "gpt-5.6-terra", "gpt-6-sol", "claude-sonnet-5", "claude-sonnet-5.5", "gemini-3.6-flash"],
  "openai-codex": ["gpt-6-luna", "gpt-5.6-luna", "gpt-5.6-terra", "gpt-6-astra", "gpt-5.5"],
};

type ModelTier = "cheap" | "normal" | "strong";

interface RouterState {
  /** A failed request promotes the next user turn to at least the normal tier. */
  retryEscalation: boolean;
}

type RouterRequest = ModelRouteRequest<RouterState>;

interface RouterDefinition {
  virtualProvider: string;
  physicalProvider: string;
  allowedModels: readonly string[];
  cheapModel: string;
  normalModel: string;
  strongModel: string;
  contextWindow: number;
}

interface RouteChoice {
  modelId: string;
  thinkingLevel: "low" | "medium" | "high";
  tier: ModelTier;
}

type ComplexitySignal = {
  rule: string;
  score: number;
};

function scorePromptLength(prompt: string): number {
  if (prompt.length >= 4_000) return 4;
  return prompt.length >= 1_600 ? 2 : 0;
}

function scoreComplexKeywords(prompt: string): number {
  return COMPLEX_TASK.test(prompt) ? 3 : 0;
}

function scoreSimpleKeywords(prompt: string): number {
  return SIMPLE_TASK.test(prompt) ? -2 : 0;
}

function scoreCodeReview(prompt: string): number {
  return CODE_REVIEW_TASK.test(prompt) ? 3 : 0;
}

function scoreFileScope(prompt: string): number {
  return (prompt.match(FILE_REFERENCE) ?? []).length >= 2 ? 3 : 0;
}

function scoreWorkItems(prompt: string): number {
  return (prompt.match(LIST_ITEM) ?? []).length >= 3 ? 3 : 0;
}

function scoreWorktreeScope(changedFiles: number): number {
  if (changedFiles >= 5) return 3;
  return changedFiles >= 2 ? 1 : 0;
}

/** Returns the individual, explainable contributions to the routing score. */
export function complexitySignals(prompt: string): ComplexitySignal[] {
  return [
    { rule: "prompt-length", score: scorePromptLength(prompt) },
    { rule: "complex-keywords", score: scoreComplexKeywords(prompt) },
    { rule: "simple-keywords", score: scoreSimpleKeywords(prompt) },
    { rule: "code-review", score: scoreCodeReview(prompt) },
    { rule: "file-scope", score: scoreFileScope(prompt) },
    { rule: "work-items", score: scoreWorkItems(prompt) },
  ].filter((signal) => signal.score !== 0);
}

/** Estimates task complexity from the newest user prompt. */
export function complexityScore(prompt: string): number {
  return complexitySignals(prompt).reduce((score, signal) => score + signal.score, 0);
}

function promptOverride(prompt: string): ModelTier | undefined {
  const value = prompt.match(OVERRIDE)?.[1]?.toLowerCase();
  return value === "cheap" || value === "normal" || value === "strong" ? value : undefined;
}

/** Determines the tier from prompt-only signals; useful for regression tests. */
export function promptTier(prompt: string): ModelTier {
  const override = promptOverride(prompt);
  if (override) return override;
  if (STRONG_TASK.test(prompt)) return "strong";
  return complexityScore(prompt) >= COMPLEXITY_THRESHOLD ? "normal" : "cheap";
}

async function worktreeSignal(cwd: string): Promise<ComplexitySignal | undefined> {
  try {
    const { stdout } = await execFileAsync("git", ["status", "--porcelain"], {
      cwd,
      timeout: 1_000,
      maxBuffer: 64 * 1024,
    });
    const changedFiles = stdout.split("\n").filter(Boolean).length;
    const score = scoreWorktreeScope(changedFiles);
    return score === 0 ? undefined : { rule: `worktree-files:${changedFiles}`, score };
  } catch {
    // A non-Git directory or unavailable Git must never block a model request.
    return undefined;
  }
}

function chooseTier(
  prompt: string,
  signals: readonly ComplexitySignal[],
  retryEscalation: boolean,
): ModelTier {
  const override = promptOverride(prompt);
  if (override) return override;
  if (STRONG_TASK.test(prompt)) return "strong";
  if (retryEscalation) return "normal";
  const score = signals.reduce((total, signal) => total + signal.score, 0);
  return score >= COMPLEXITY_THRESHOLD ? "normal" : "cheap";
}

function routeTo(
  ctx: ExtensionContext,
  provider: string,
  choice: RouteChoice,
  state: RouterState,
): ModelRoute<RouterState> {
  const model = ctx.modelRegistry.find(provider, choice.modelId);
  if (!model) {
    throw new Error(
      `Auto router requires ${provider}/${choice.modelId}. Authenticate the provider and verify it with pi --list-models.`,
    );
  }
  return { model, thinkingLevel: choice.thinkingLevel, state };
}

function lastUserText(messages: readonly Message[]): string {
  const content = messages.filter((message) => message.role === "user").at(-1)?.content ?? "";
  if (typeof content === "string") return content;
  return content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n");
}

function availableModelIds(ctx: ExtensionContext, definition: RouterDefinition): Set<string> {
  const allowed = new Set(definition.allowedModels);
  return new Set(ctx.modelRegistry
    .getAvailable()
    .filter((model) => model.provider === definition.physicalProvider && allowed.has(model.id) && model.type === "chat" && model.reasoning)
    .map((model) => model.id));
}

function selectRoute(
  request: RouterRequest,
  ctx: ExtensionContext,
  definition: RouterDefinition,
  tier: ModelTier,
): RouteChoice {
  const available = availableModelIds(ctx, definition);
  if (available.size === 0) {
    throw new Error(`Auto router found no available reasoning models for ${definition.physicalProvider}.`);
  }

  const cheapModel = available.has(definition.cheapModel)
    ? definition.cheapModel
    : definition.allowedModels.find((id) => available.has(id))!;
  const normalModel = available.has(definition.normalModel) ? definition.normalModel : cheapModel;
  const strongModel = available.has(definition.strongModel) ? definition.strongModel : normalModel;
  const modelId = tier === "strong" ? strongModel : tier === "normal" ? normalModel : cheapModel;
  const thinkingLevel = request.thinkingLevel === "high" ? "high" : request.thinkingLevel === "low" ? "low" : "medium";

  return { modelId, thinkingLevel, tier };
}

function logRoute(definition: RouterDefinition, choice: RouteChoice, signals: readonly ComplexitySignal[]) {
  if (!DEBUG) return;
  const score = signals.reduce((total, signal) => total + signal.score, 0);
  const reasons = signals.map((signal) => `${signal.rule}=${signal.score}`).join(", ") || "none";
  console.error(`[cost-router] provider=${definition.virtualProvider} tier=${choice.tier} model=${choice.modelId} score=${score} reasons=${reasons}`);
}

function registerCostRouter(pi: ExtensionAPI, definition: RouterDefinition) {
  pi.registerVirtualModel<RouterState>({
    provider: definition.virtualProvider,
    id: "auto",
    name: "Auto (complexity-aware)",
    thinkingLevels: [...THINKING_LEVELS],
    contextWindow: definition.contextWindow,
    maxTokens: 128_000,
    async route(request, ctx) {
      const sticky = request.failed ?? request.previous;
      if (request.reason !== "user" && sticky) {
        // Keep tool follow-ups and retries on their starting model for cache reuse.
        return {
          model: sticky.model,
          thinkingLevel: sticky.thinkingLevel ?? request.thinkingLevel,
          state: { retryEscalation: request.reason === "retry" || request.state?.retryEscalation === true },
        };
      }

      const prompt = lastUserText(request.messages);
      const signals = complexitySignals(prompt);
      const diffSignal = await worktreeSignal(ctx.cwd);
      if (diffSignal) signals.push(diffSignal);
      const tier = request.thinkingLevel === "high"
        ? "strong"
        : chooseTier(prompt, signals, request.state?.retryEscalation === true);
      const choice = selectRoute(request, ctx, definition, tier);
      logRoute(definition, choice, signals);
      return routeTo(ctx, definition.physicalProvider, choice, { retryEscalation: false });
    },
  });
}

export default function (pi: ExtensionAPI) {
  registerCostRouter(pi, {
    virtualProvider: "github-copilot",
    physicalProvider: "github-copilot",
    allowedModels: MODEL_ALLOWLIST["github-copilot"],
    cheapModel: MODEL_TIERS["github-copilot"].cheap,
    normalModel: MODEL_TIERS["github-copilot"].normal,
    strongModel: MODEL_TIERS["github-copilot"].strong,
    contextWindow: 1_100_000,
  });

  registerCostRouter(pi, {
    virtualProvider: "openai-codex",
    physicalProvider: "openai-codex",
    allowedModels: MODEL_ALLOWLIST["openai-codex"],
    cheapModel: MODEL_TIERS["openai-codex"].cheap,
    normalModel: MODEL_TIERS["openai-codex"].normal,
    strongModel: MODEL_TIERS["openai-codex"].strong,
    contextWindow: 272_000,
  });
}
