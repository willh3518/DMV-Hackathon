# AGENTS.md

This file defines the working rules for coding agents and contributors in this repository.

## Start here

1. Inspect the repository, current branch, and working tree before changing anything.
2. Preserve existing work. Do not delete, overwrite, or reformat unrelated files.
3. Keep changes small enough to review during a 12-hour hackathon.
4. Explain important assumptions in the pull request or handoff.
5. Do not select or introduce a final product name without explicit team approval.

## Project intent

Build a conversational place-discovery product that evaluates whether a restaurant or other place fits one person's accessibility needs.

The core domain rules are non-negotiable:

- Accessibility must be modeled as separate attributes, not one universal accessibility score.
- A match score must be personalized from the user's saved profile and current request.
- Missing evidence means **unknown**, never inaccessible.
- Business-declared accessibility and customer-observed accessibility must remain distinguishable.
- Evidence should retain its source, age, specificity, consistency, and confidence.
- User-facing results must explain strengths, concerns, and uncertainty.

## Planned stack

- Flutter client targeting the platforms selected by the team
- Supabase for authentication, Postgres data, storage, and server-side functions as needed

The repository currently contains documentation only. When scaffolding begins, adapt to the checked-in structure rather than regenerating or replacing existing work.

## Accessibility requirements

Accessibility is a release requirement, not a later enhancement.

- Target WCAG 2.2 AA where applicable.
- Support screen readers, keyboard navigation, switch access, and text scaling.
- Give interactive controls clear semantic names, roles, states, and focus order.
- Maintain sufficient color contrast and never communicate status through color alone.
- Use comfortable touch targets and spacing; target at least 48 by 48 logical pixels in Flutter.
- Respect reduced-motion and platform accessibility preferences.
- Keep language direct and avoid presenting uncertain evidence as fact.
- Test critical flows with accessibility tooling and at least one real assistive-technology pass when possible.

## Data and privacy

Accessibility profiles can contain sensitive personal information.

- Collect only the data needed to personalize results.
- Never commit credentials, API keys, tokens, user records, or production data.
- Keep privileged Supabase keys on trusted server-side surfaces only.
- Use Row Level Security for user-owned data.
- Prefer explicit consent and clear retention behavior.
- Avoid exposing full review text when a minimal evidence excerpt or structured observation is sufficient.

## Engineering workflow

- Use feature-oriented, testable boundaries instead of a single large application file.
- Keep scoring logic deterministic, inspectable, and covered by unit tests.
- Keep source evidence attached to derived accessibility assessments.
- Add database changes through versioned migrations.
- Use environment configuration for deployment-specific values.
- Run formatting, static analysis, and relevant tests before committing.
- Document setup changes in the README.

## Definition of done

A change is ready when:

- It satisfies the requested behavior without unrelated scope.
- Loading, empty, error, unknown-evidence, and success states are considered.
- Accessibility and privacy implications have been reviewed.
- Relevant tests pass.
- Documentation reflects any setup or architectural change.
- No secrets or generated build artifacts are included.

