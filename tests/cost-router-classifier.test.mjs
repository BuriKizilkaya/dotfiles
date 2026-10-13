import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const { loadCostRouterSettings, parseTierClassification } = await import("../home/dot_pi/agent/extensions/cost-router.ts");

for (const tier of ["cheap", "normal", "strong"]) {
  test(`accepts System One-compatible ${tier} choice`, () => {
    const value = JSON.stringify({
      answers: { tier: { type: "choice", choice: tier, confidence: 0.9 } },
    });
    assert.equal(parseTierClassification(value), tier);
  });
}

test("rejects malformed classifier JSON", () => {
  assert.throws(() => parseTierClassification("not json"), /invalid JSON/);
});

test("rejects a response without a valid tier", () => {
  assert.throws(
    () => parseTierClassification('{"answers":{"tier":{"type":"choice","choice":"other"}}}'),
    /no valid tier/,
  );
});

test("fails clearly when the settings file is missing", () => {
  assert.throws(
    () => loadCostRouterSettings("/tmp/cost-router-settings-does-not-exist.json"),
    /Cost router settings not found/,
  );
});

test("loads cheap-model and System One settings", () => {
  const directory = mkdtempSync(join(tmpdir(), "cost-router-"));
  const path = join(directory, "cost-router-settings.json");
  try {
    writeFileSync(path, JSON.stringify({
      classifier: {
        type: "system-one",
        models: { "github-copilot": "gpt-6-luna" },
        systemOne: { url: "http://127.0.0.1:11434/", model: "tev1" },
      },
      providers: {
        "github-copilot": {
          contextWindow: 1_100_000,
          allowedModels: ["gpt-6-luna", "gpt-5.6-terra", "gpt-6.1-sol"],
          cheap: "gpt-6-luna",
          normal: "gpt-5.6-terra",
          strong: "gpt-6.1-sol",
        },
      },
    }));
    const settings = loadCostRouterSettings(path);
    assert.equal(settings.classifier.type, "system-one");
    assert.deepEqual(settings.classifier.systemOne, { url: "http://127.0.0.1:11434", model: "tev1" });
    assert.equal(settings.providers["github-copilot"].contextWindow, 1_100_000);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
