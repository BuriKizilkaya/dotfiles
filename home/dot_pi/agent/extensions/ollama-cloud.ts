import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type OpenAIModelsResponse = {
  data?: Array<{
    id: string;
    name?: string;
    context_window?: number;
    max_tokens?: number;
  }>;
};

const DEFAULT_BASE_URL = "https://ollama.com/v1";
const DEFAULT_CONTEXT_WINDOW = 131072;
const DEFAULT_MAX_TOKENS = 8192;

const normalizeBaseUrl = (url: string): string => url.replace(/\/+$/, "");

const parseFallbackModels = () => {
  const raw = process.env.OLLAMA_CLOUD_MODELS ?? "";
  return raw
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean)
    .map((id) => ({
      id,
      name: id,
      reasoning: false,
      input: ["text"] as Array<"text" | "image">,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: DEFAULT_CONTEXT_WINDOW,
      maxTokens: DEFAULT_MAX_TOKENS,
    }));
};

export default async function (pi: ExtensionAPI) {
  const baseUrl = normalizeBaseUrl(process.env.OLLAMA_CLOUD_BASE_URL ?? DEFAULT_BASE_URL);
  const apiKey = process.env.OLLAMA_CLOUD_API_KEY;

  let models: Array<{
    id: string;
    name: string;
    reasoning: boolean;
    input: Array<"text" | "image">;
    cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
    contextWindow: number;
    maxTokens: number;
    compat?: {
      supportsDeveloperRole?: boolean;
      maxTokensField?: "max_completion_tokens" | "max_tokens";
    };
  }> = [];

  try {
    const response = await fetch(`${baseUrl}/models`, {
      headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : undefined,
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch models: ${response.status} ${response.statusText}`);
    }

    const payload = (await response.json()) as OpenAIModelsResponse;
    const discovered = payload.data ?? [];

    models = discovered.map((model) => ({
      id: model.id,
      name: model.name ?? model.id,
      reasoning: false,
      input: ["text"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: model.context_window ?? DEFAULT_CONTEXT_WINDOW,
      maxTokens: model.max_tokens ?? DEFAULT_MAX_TOKENS,
      compat: {
        supportsDeveloperRole: false,
        maxTokensField: "max_tokens",
      },
    }));
  } catch {
    models = parseFallbackModels();
  }

  pi.registerProvider("ollama-cloud", {
    name: "Ollama Cloud",
    baseUrl,
    apiKey: "$OLLAMA_CLOUD_API_KEY",
    api: "openai-completions",
    authHeader: true,
    headers: {
      "Content-Type": "application/json",
    },
    models,
  });
}
