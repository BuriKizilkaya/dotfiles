import assert from "node:assert/strict";
import test from "node:test";

const { MODEL_TIERS, promptTier } = await import("../home/dot_pi/agent/extensions/cost-router.ts");

const cases = [
  ["Benenne die Variable `result` in `response` um.", "cheap"],
  ["Bitte korrigiere den Typo in der README.", "cheap"],
  ["Erstelle ein Threat Model für die Architektur dieser Anwendung.", "strong"],
  ["Analysiere die Race Condition beim parallelen Schreiben.", "normal"],
  ["Mache ein Code Review für diesen Pull Request.", "normal"],
  ["Ändere src/api.ts und src/auth.ts, damit beide Endpunkte dieselbe Validierung verwenden.", "normal"],
  ["- Analysiere den Fehler\n- Passe die Migration an\n- Ergänze Tests", "normal"],
  ["a".repeat(1_600), "cheap"],
  ["a".repeat(4_000), "normal"],
  ["!cheap Erstelle ein Threat Model für die Architektur.", "cheap"],
  ["!strong Benenne die Variable um.", "strong"],
];

for (const [prompt, expectedTier] of cases) {
  test(`${expectedTier}: ${prompt.slice(0, 70)}`, () => {
    const tier = promptTier(prompt);
    assert.equal(tier, expectedTier);
    assert.equal(MODEL_TIERS["github-copilot"][tier], expectedTier === "strong" ? "gpt-6-sol" : expectedTier === "normal" ? "gpt-5.6-terra" : "gpt-6-luna");
    assert.equal(MODEL_TIERS["openai-codex"][tier], expectedTier === "strong" ? "gpt-6-astra" : expectedTier === "normal" ? "gpt-5.6-terra" : "gpt-6-luna");
  });
}
