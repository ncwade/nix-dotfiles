---
name: tech-spec
description: Produce a concise, code-shaped technical specification (types, interfaces, module boundaries, call stacks with error paths, and Red-Green-Refactor test plan) instead of a prose PRD.
---

# Tech Spec

Write an implementation-ready, code-shaped specification instead of a prose PRD. Prefer concrete types, signatures, and failure paths over narrative explanation.

## Structure

1. **Goal & Scope**
   - 2–3 bullets stating the problem, target behavior, and explicit non-goals.

2. **Data Structures & Contracts**
   - Define concrete types, interfaces, schemas, config keys, or Nix options in the target language (TypeScript, Nix, Go, etc.).
   - Include invariants, defaults, and serialization shapes.

3. **Boundaries & Seams**
   - State module ownership, public vs. internal surface, mutable vs. immutable state boundaries, and how failures are isolated.

4. **Call Stacks & Control Flow**
   - Trace each primary entry point through its helper calls using explicit `(input) -> output | error` signatures.
   - Call out edge cases, timeouts, retries, and error propagation.

5. **Red-Green-Refactor Test Plan**
   - **Red**: Numbered failing unit/integration tests to write first (including edge cases and error paths).
   - **Green**: Minimal implementation steps to make each test pass.
   - **Refactor**: Duplication removal, helper extraction, or naming cleanup after green.

6. **Open Questions**
   - List only blocking design decisions; omit speculative padding.
