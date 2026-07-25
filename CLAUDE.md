# CLAUDE.md

Read and follow [AGENTS.md](AGENTS.md) before making changes. The frontend operating loop is documented in [docs/FRONTEND_WORKFLOW.md](docs/FRONTEND_WORKFLOW.md).

## Required orchestration

Frontend development is always subagent-driven. Act as the coordinator:

1. Inspect the worktree and define a bounded slice.
2. Delegate planning or exploration.
3. Assign implementation to the project-local `flutter-ui-builder` with explicit file ownership.
4. Use `everything-claude-code:a11y-architect` when the flow affects semantics, focus, text scaling, motion, or sensitive profile input.
5. Run the relevant Flutter quality gates.
6. Delegate the final diff to `everything-claude-code:flutter-reviewer`.
7. Invoke `everything-claude-code:dart-build-resolver` only for a concrete failing build or analyzer result.

Do not let concurrent subagents edit the same files. The coordinator owns integration and resolves handoffs.

## Everything Claude Code

Everything Claude Code is already installed in the current developer environment. Teammates can verify it with:

```bash
claude plugin details everything-claude-code@everything-claude-code
```

The workspace relies on its planner, TDD guide, accessibility architect, Flutter reviewer, Dart build resolver, and Flutter build/test/review skills. Project instructions take precedence if an upstream agent suggests backend or infrastructure work.

## Product guardrails

- The product name is not selected. Do not invent one.
- The Flutter client displays contract-supplied scores and evidence; it does not calculate match scores.
- Missing evidence remains unknown.
- Do not implement backend, Supabase administration, ingestion, scoring services, or infrastructure from this frontend workspace.
