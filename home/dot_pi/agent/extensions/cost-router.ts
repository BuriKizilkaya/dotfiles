import type { Message } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  ModelRoute,
  ModelRouteRequest,
} from "@earendil-works/pi-coding-agent";

const THINKING_LEVELS = ["low", "medium", "high"] as const;
const COMPLEX_TASK = /\b(architecture|architektur|design|security|sicherheit|threat model|migration|migrate|refactor|projektweit|cross[- ]cutting|mehrere dateien|root cause|race condition|concurrency|parallelism|performance|profil(?:e|ing)|komplex|schwierig)\b/i;
const LARGE_PROMPT_CHARS = 1_600;

// Explicitly allow only the inexpensive defaults and one stronger fallback tier.
const MODEL_ALLOWLIST: Record<string, readonly string[]> = {
  "github-copilot": ["gpt-6-luna", "gpt-5.6-luna", "gpt-5.6-terra", "claude-sonnet-5", "claude-sonnet-5.5", "gemini-3.6-flash"],
  "openai-codex": ["gpt-6-luna", "gpt-5.6-luna", "gpt-5.6-terra", "gpt-5.5"],
};

type RouterState = undefined;
type RouterRequest = ModelRouteRequest<RouterState>;

interface RouterDefinition {
  /** Virtual model's provider in Pi's model picker, e.g. github-copilot/auto. */
  virtualProvider: string;
  /** Physical provider that must be authenticated in Pi. */
  physicalProvider: string;
  /** Model IDs the router is allowed to select. */
  allowedModels: readonly string[];
  contextWindow: number;
}

interface RouteChoice {
  modelId: string;
  thinkingLevel: "low" | "medium" | "high";
}

interface PricedModel {
  id: string;
  score: number;
}

function routeTo(
  ctx: ExtensionContext,
  provider: string,
  choice: RouteChoice,
): ModelRoute<RouterState> {
  const model = ctx.modelRegistry.find(provider, choice.modelId);
  if (!model) {
    throw new Error(
      `Auto router requires ${provider}/${choice.modelId}. Authenticate the provider and verify it with pi --list-models.`,
    );
  }

  return { model, thinkingLevel: choice.thinkingLevel };
}

function lastUserText(messages: readonly Message[]): string {
  const content = messages.filter((message) => message.role === "user").at(-1)?.content ?? "";
  if (typeof content === "string") return content;
  return content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n");
}

function costScore(model: { cost?: { input?: number; output?: number } }): number | null {
  const input = model.cost?.input;
  const output = model.cost?.output;
  return typeof input === "number" && typeof output === "number" ? input + output : null;
}

function availableModels(ctx: ExtensionContext, provider: string, allowedModels: readonly string[]): PricedModel[] {
  const allowed = new Set(allowedModels);
  return ctx.modelRegistry
    .getAvailable()
    .filter((model) => model.provider === provider && allowed.has(model.id) && model.type === "chat" && model.reasoning)
    .flatMap((model) => {
      const score = costScore(model);
      return score === null ? [] : [{ id: model.id, score }];
    });
}

function selectRoute(request: RouterRequest, ctx: ExtensionContext, definition: RouterDefinition): RouteChoice {
  const provider = definition.physicalProvider;
  // Pi loads its current catalog at startup. Resolve candidates per user request
  // so model-catalog refreshes and changed provider availability take effect too.
  const candidates = availableModels(ctx, provider, definition.allowedModels).sort((a, b) => a.score - b.score);
  if (candidates.length === 0) {
    throw new Error(`Auto router found no priced reasoning models for ${provider}.`);
  }

  const cheapest = candidates[0];
  const stronger = candidates.at(-1)!;

  // Thinking level controls reasoning effort, never model price/tier.
  if (request.thinkingLevel === "high") {
    return { modelId: cheapest.id, thinkingLevel: "high" };
  }
  if (request.thinkingLevel === "low") {
    return { modelId: cheapest.id, thinkingLevel: "low" };
  }

  // Routine prompts stay on the cheapest model. Harder tasks use the strongest
  // explicitly allowed model, never an unlisted high-end model.
  const prompt = lastUserText(request.messages);
  return prompt.length >= LARGE_PROMPT_CHARS || COMPLEX_TASK.test(prompt)
    ? { modelId: stronger.id, thinkingLevel: "medium" }
    : { modelId: cheapest.id, thinkingLevel: "low" };
}

function registerCostRouter(pi: ExtensionAPI, definition: RouterDefinition) {
  pi.registerVirtualModel<RouterState>({
    provider: definition.virtualProvider,
    id: "auto",
    name: "Auto (complexity-aware)",
    thinkingLevels: [...THINKING_LEVELS],
    contextWindow: definition.contextWindow,
    maxTokens: 128_000,
    route(request, ctx) {
      // Keep all tool follow-ups and retries on the model that started the turn.
      // This avoids switching models mid-turn and losing prompt-cache benefits.
      const sticky = request.failed ?? request.previous;
      if (request.reason !== "user" && sticky) {
        return {
          model: sticky.model,
          thinkingLevel: sticky.thinkingLevel ?? request.thinkingLevel,
        };
      }

      return routeTo(ctx, definition.physicalProvider, selectRoute(request, ctx, definition));
    },
  });
}

export default function (pi: ExtensionAPI) {
  registerCostRouter(pi, {
    virtualProvider: "github-copilot",
    physicalProvider: "github-copilot",
    allowedModels: MODEL_ALLOWLIST["github-copilot"],
    contextWindow: 1_100_000,
  });

  registerCostRouter(pi, {
    virtualProvider: "openai-codex",
    physicalProvider: "openai-codex",
    allowedModels: MODEL_ALLOWLIST["openai-codex"],
    contextWindow: 272_000,
  });
}
