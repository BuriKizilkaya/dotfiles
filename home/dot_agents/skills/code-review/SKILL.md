---
name: code-review
description: Thorough code review covering bugs, security, performance, maintainability, and test coverage. Use when asked to review code, a PR, a diff, or a file.
---

# Code Review

Perform a structured code review of the provided code, file, or diff.

## Process

1. **Understand context** — Read the code fully before commenting. If reviewing a diff, fetch the surrounding context with `read` if needed.
2. **Run the checklist** — Work through each category below systematically.
3. **Summarize findings** — Group by severity: 🔴 Critical / 🟠 Major / 🟡 Minor / 🟢 Suggestion.
4. **Propose fixes** — For each non-trivial issue, show a concrete fix or improved snippet.

## Review Checklist

### Correctness & Logic
- Off-by-one errors, wrong conditions, incorrect loop bounds
- Null / undefined / empty checks missing
- Edge cases not handled (empty input, zero, negative numbers, large values)
- Race conditions or incorrect async/await usage
- Wrong return values or missing returns

### Security
- Injection risks (SQL, shell, template, path traversal)
- Secrets or credentials hardcoded or logged
- Input not validated or sanitized
- Auth/authz checks missing or bypassable
- Insecure defaults (weak crypto, plain HTTP, verbose errors to clients)

### Performance
- N+1 query patterns
- Unnecessary re-computation inside loops
- Missing indexes or inefficient data structures
- Blocking I/O where async would fit
- Memory leaks (event listeners, timers, open handles not cleaned up)

### Maintainability
- Functions doing more than one thing (SRP violations)
- Magic numbers or strings without named constants
- Deep nesting that could be flattened
- Duplicated logic that could be extracted
- Misleading names (variables, functions, types)

### Error Handling
- Errors silently swallowed
- Generic catch blocks hiding the real error
- Missing user-facing error messages
- Stack traces exposed in production paths

### Tests
- Happy path covered but edge cases missing
- Assertions too loose (e.g. `toBeTruthy` instead of exact value)
- Tests coupled to implementation details
- Missing tests for the changed code paths

## Output Format

```
## Code Review

### 🔴 Critical
- [file:line] Issue description
  ```suggestion
  fixed code
  ```

### 🟠 Major
...

### 🟡 Minor
...

### 🟢 Suggestions
...

### Summary
X critical, Y major, Z minor issues found.
```
