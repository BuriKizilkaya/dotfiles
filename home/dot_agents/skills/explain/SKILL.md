---
name: explain
description: Explains code, architecture, concepts, or errors at the right level of detail. Use when asked to explain what something does, how it works, or why an error occurs.
---

# Explain

Explain the target (code, file, concept, error, architecture) clearly and at the right depth for the request.

## Process

1. **Identify the target** — What exactly needs explaining? A function, file, pattern, error message, or system?
2. **Gauge depth** — Default to a layered explanation: start high-level, then drill into details.
3. **Use concrete examples** — Where abstract, show a minimal example or analogy.
4. **Explain the why** — Not just what the code does, but why it's written that way.

## Explanation Layers

### Layer 1 — One-line summary
What does this do in plain English? No jargon.

### Layer 2 — High-level walkthrough
What are the key moving parts? How do they fit together? Use a diagram or numbered steps if it helps.

### Layer 3 — Detailed walkthrough
Go line-by-line or section-by-section through the important parts. Highlight:
- Non-obvious logic
- Key algorithms or data structures used
- Important side effects
- External dependencies and why they're needed

### Layer 4 — Design decisions
- Why is it structured this way?
- What trade-offs were made?
- What alternatives exist and why were they not chosen?

## Special Cases

### Explaining an error
1. State what the error means literally
2. Identify the most likely root cause given the context
3. Show what triggers it (minimal reproduction if possible)
4. Provide the fix

### Explaining architecture
1. Draw a text diagram of components and their relationships
2. Describe data flow end-to-end
3. Identify boundaries (service, module, process)
4. Note key design patterns in use

### Explaining a concept
1. One-sentence definition
2. Concrete analogy
3. Code example showing it in practice
4. Common pitfalls

## Output Format

Adapt depth to what was asked:
- "What does this do?" → Layer 1 + 2
- "Explain this code" → Layer 1 + 2 + 3
- "Why is it written like this?" → Layer 3 + 4
- "Explain this error" → Error case
