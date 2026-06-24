---
name: plan
description: Breaks down a feature, task, or problem into a clear, ordered, actionable implementation plan. Use when asked to plan, design, or figure out how to implement something before writing code.
---

# Plan

Create a concrete, ordered implementation plan before writing any code.

## Process

1. **Clarify the goal** — If the request is ambiguous, ask one focused clarifying question before proceeding. Don't ask multiple questions at once.
2. **Explore the codebase** — Use `read` and `bash` to understand the existing structure, conventions, and relevant files before planning.
3. **Identify constraints** — What must stay the same? What are the performance, security, or compatibility requirements?
4. **Draft the plan** — Break the work into steps following the format below.
5. **Validate** — Review the plan for missing steps, wrong order, or hidden complexity before presenting it.

## Exploration Checklist

Before planning, answer these by reading the code:
- [ ] What files are relevant to this change?
- [ ] What existing patterns/conventions should the plan follow?
- [ ] Are there tests that need updating?
- [ ] Are there config files, migrations, or schemas involved?
- [ ] Are there dependencies or integrations affected?

## Plan Format

```
## Plan: [Feature / Task Name]

### Goal
One sentence: what does done look like?

### Approach
Brief description of the chosen strategy and why (vs alternatives).

### Steps

1. **[Step title]** — [What to do and why]
   - Files: `path/to/file.ts`
   - Notes: any gotchas or decisions to make

2. **[Step title]** — ...

### Dependencies between steps
Note any steps that must be completed before others, if non-obvious.

### Out of scope
List things explicitly not included in this plan.

### Open questions
Any decisions that need input before or during implementation.

### Estimated complexity
Small / Medium / Large — and why.
```

## Guidelines

- **Steps should be independently testable** — after each step the codebase should still work (or at least compile).
- **One concern per step** — don't bundle refactoring with feature work.
- **Name the files** — always include which files will be created or changed.
- **Flag risks** — if a step is high-risk (data migration, breaking API change), call it out.
- **Don't over-plan** — for small tasks (< 1 hour), a short bullet list is enough. Reserve the full format for complex work.
