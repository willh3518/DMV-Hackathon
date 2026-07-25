# Version 1 Delivery Plan

## Objective

Deliver the [Version 1 product specification](V1_PRODUCT_SPEC.md) as a
reviewable Flutter frontend during a 12-hour hackathon. Work is divided into
bounded, exclusive subagent slices, followed by single-owner integration and
independent review.

The Flutter client renders contract-supplied match scores, attribute assessments,
evidence, confidence, and explanations. It must not calculate, rank, or infer
them.

## 12-hour scope

The critical demonstration is:

```text
Landing -> Authentication -> Five questions -> Chat
                                      |
                                      `-> Chat/Profile application
```

Chat and Profile are the only persistent tabs. Recommendation detail, location,
legal content, sign out, and delete-account confirmation are supporting surfaces.
Non-goals in the product specification remain outside the 12-hour scope.

## Working rules

- Follow [AGENTS.md](../AGENTS.md) and the
  [frontend workflow](FRONTEND_WORKFLOW.md).
- The coordinator may have no more than three active subagents at once.
- Every implementation subagent receives one bounded slice and exclusive paths.
- Other agents may be active; preserve their work and never reset, clean, revert,
  delete, or broadly reformat unrelated changes.
- Shared integration surfaces have one owner at a time.
- Establish user goal, visual thesis, content, states, interaction, and
  accessibility behavior before implementation.
- Use typed interfaces and synthetic fixtures until external services are ready.
- Review accessibility and Flutter quality after implementation.
- Use a build resolver only for a concrete analyzer, dependency, or build failure.
- Do not select a final name, invent legal text, assume an auth method/provider,
  or promise deletion before contract confirmation.

## Approved baseline prerequisite

The current worktree contains substantial uncommitted work. Before parallel
feature implementation:

1. Inspect the complete diff.
2. Run format, analysis, tests, and platform checks appropriate to the baseline.
3. Obtain user approval of the current landing build.
4. Create an approved baseline commit through the authorized coordinator.
5. Record its commit identifier in the implementation handoff.

No parallel builder phase starts before this baseline exists. This plan does not
authorize a commit by itself.

## Exclusive ownership matrix

| Surface | Owner | Parallel edit rule |
| --- | --- | --- |
| `frontend/lib/app/` | Coordinator/integration owner | Phase 6 integration; no builder edits |
| `frontend/lib/domain/` | Coordinator/domain owner | No builder edits |
| `frontend/lib/contracts/` | Coordinator/contracts owner | No builder edits |
| Existing landing entry and route wiring | Coordinator | Builders consume, do not edit |
| Shared design-system component files | Foundation builder | One named owner per file |
| Shared onboarding shell files | Onboarding-shell builder | Question builders consume only |
| `features/authentication/` | Authentication builder | Exclusive during Phase 1 |
| Q1, Q2, Q3 feature files/tests | One question builder each | No shared shell or sibling edits |
| Q4, Q5 feature files/tests | One question builder each | No shared shell or sibling edits |
| Completion presentation files/tests | Completion builder | No app routing edits |
| `features/chat/` | Chat builder | Exclusive during Phase 5 |
| `features/profile/` | Profile builder | Exclusive during Phase 5 |
| `features/recommendations/` | Recommendation builder | Exclusive during Phase 5 |
| Read-only reviews | Reviewer agents | No file edits |

The coordinator publishes exact paths before each batch. If a required file is
already assigned, work waits or is reassigned rather than creating concurrent
ownership.

## Timeline and phases

### Phase 0 - Specification, contracts, and baseline (`0:00-0:45`)

Deliverables:

- Approved product specification and delivery plan.
- Decision log with blockers assigned.
- Frontend contract/model outline.
- Synthetic fixture matrix.
- Verified and approved baseline commit.

Agents:

- One read-only product-flow planner.
- One read-only accessibility/risk reviewer.
- Coordinator owns documents, contracts, and baseline.

Gate:

- Intended routing state machine is agreed.
- Landing remains the approved visual source of truth.
- No unresolved blocker prevents shared foundation and auth work.

### Phase 1 - Shared shell and authentication (`0:45-2:00`)

Parallel slices, maximum three builders:

1. Design-system builder: shared selection, field, status, action, and motion
   components in exclusively assigned files.
2. Onboarding-shell builder: progress, Back, Skip/Continue, focus, large-text, and
   direction-aware transition shell.
3. Authentication builder: sign-up/sign-in presentation and focused tests against
   the coordinator-supplied interface.

Dependencies:

- Baseline commit.
- Contract signatures and synthetic auth states.
- Approved visual/motion requirements.

Review gate:

- Landing still passes existing tests and remains visually intact.
- Shared shell passes semantics, target, contrast, 3.2x text, focus, and
  reduced-motion tests.
- Authentication covers validation, loading, failure, complete, and incomplete
  profile responses.

Phone approval gate:

- User reviews Landing -> Authentication and the shared question shell on iPhone.

### Phase 2 - Questions 1-3 in parallel (`2:00-3:15`)

Builders:

- Q1 builder: accommodations and constraint-candidate semantics.
- Q2 builder: grouped food preferences, explicit dietary requirements, service,
  communication, and environment preferences.
- Q3 builder: walking/rolling/transit-inclusive travel-limit input.

Each builder owns only its screen-specific widgets and tests. The coordinator
supplies shared components and draft-state callbacks.

Gate:

- Selection states and custom/Skip behavior pass tests.
- Q2 is grouped rather than one large chip list.
- Q2 preserves explicit allergy/medical dietary requirements without claiming
  independent allergy-safety verification.
- Q3 does not infer capability from disability and displays clear units.
- No question computes priority or matching.

### Phase 3 - Questions 4-5 and completion (`3:15-4:30`)

Builders:

- Q4 builder: interests and hobbies.
- Q5 builder: functional situations and distinct None/Prefer not to say/Skip.
- Completion builder: completion presentation, pending, failure, and confirmed
  states without app route ownership.

Gate:

- Q4 supports restaurant and activity interests.
- Q5 mutual-exclusion and state distinctions pass tests.
- Completion never displays success before contract confirmation.

### Phase 4 - Onboarding integration (`4:30-5:30`)

Single owner: coordinator/integration owner.

Deliverables:

- Landing -> Authentication -> Q1-Q5 -> Chat routing.
- Returning-complete and returning-incomplete routing.
- Draft preservation through forward/back/Skip.
- Session loading, authentication failure, and expiration handling.
- Completion contract and focus handoff.

Review gate:

- Critical onboarding integration test passes.
- Read-only accessibility review has no blocker.

Phone approval gate:

- User completes and reverses the full onboarding flow on iPhone.

### Phase 5 - Chat, Profile, and Recommendations in parallel (`5:30-8:30`)

Builders:

1. Chat builder: greeting, suggested prompts, composer, clarification, loading,
   no-results, retry, service, and session states.
2. Profile builder: initial loading/load failure/retry, five editable sections,
   account area, legal link/content loading/unavailable/failure/retry, save states,
   sign out, and delete-account presentation.
3. Recommendation builder: card, attribute status, declared/observed evidence,
   unknown/partial states, place detail, external actions, and supplied-action
   launch failure with Retry or an available alternative.

Dependencies:

- Stable domain and contract models owned by the coordinator.
- Synthetic fixtures covering the product-specification matrix.
- Shared design components.

Review gate:

- Every slice passes focused widget and accessibility tests.
- Match score/evidence are rendered exactly as supplied; no scoring logic exists
  in the client.
- Profile and legal surfaces do not display fabricated or stale content after a
  load failure and provide Retry.
- Directions, call, website, and reservation failure fixtures provide actionable
  feedback and recovery.
- Delete success appears only after confirmed completion.
- Legal surfaces use supplied or explicit non-production placeholder content.

Phone approval gate:

- User reviews Chat, Profile, recommendation cards, and place detail on iPhone
  before application integration.

### Phase 6 - Single-owner application integration (`8:30-10:00`)

Single owner: coordinator/integration owner.

Deliverables:

- Chat/Profile two-tab shell.
- Session, onboarding, profile, discovery, location, and external-action wiring.
- Recommendation-to-detail and detail focus return.
- Just-in-time location request and manual city/area fallback.
- Sign-out and delete-account contract state handling.
- Critical mocked end-to-end integration test.

Gate:

- Persistent navigation has exactly two destinations.
- All location states render and denial does not block manual discovery.
- Unknown evidence never renders as inaccessible.
- New, returning-complete, returning-incomplete, signed-out, and expired-session
  flows match the specification.

### Phase 7 - Independent review and fixes (`10:00-11:00`)

Read-only reviewers, run concurrently:

- Accessibility reviewer.
- Flutter/Dart reviewer.
- Responsive/motion/test-coverage reviewer.

The coordinator assigns every accepted finding to one narrow owner. Reviewers do
not edit. A build resolver is spawned only if a real failure exists.

Gate:

- No unresolved release-blocking finding.
- Accepted non-blockers are documented with owner and rationale.

### Phase 8 - Frontend MVP demo-candidate builds and buffer (`11:00-12:00`)

Deliverables:

- Full validation command set.
- Android debug build.
- Physical iPhone install and launch using the documented temporary build path.
- VoiceOver critical-flow pass; TalkBack pass when an Android device/emulator is
  available.
- Diff audit for secrets, personal data, generated artifacts, and scope.
- Final phone approval and demo rehearsal.

## Standard subagent task packet

Every builder assignment includes:

- User goal and requirement IDs.
- Visual, content, and interaction thesis.
- Required default, loading, empty, partial, error, and success states.
- Accessibility behavior: semantics, focus, scaling, contrast, target size, input,
  and reduced motion.
- Exact owned files and explicitly forbidden/shared files.
- Supplied contract signatures and synthetic fixtures.
- Required focused tests and validation commands.
- Reminder that other agents are active and unrelated work must be preserved.
- Instruction to report files, tests, assumptions, dependencies, and risks.

## Per-slice definition of done

A slice is accepted when:

- It satisfies assigned requirement IDs without unrelated scope.
- Only assigned files changed.
- Required states and honest pending/error copy exist.
- Domain/scoring/backend logic was not introduced.
- Widget tests cover primary behavior and at least one failure/edge state.
- Semantic names, roles, values, and selection states are correct.
- The complete slice is operable in logical order by keyboard and switch access,
  including primary, secondary, and destructive actions, with no input trap.
- Targets are at least 48 by 48 logical pixels.
- Text scales to 3.2x without clipped required content.
- Status is not communicated only by color.
- Reduced motion is respected.
- Focus entry and return are explicit where applicable.
- Formatter, analyzer, and focused tests pass.
- Handoff lists assumptions and remaining external dependencies.

## Validation commands

Run from `frontend/`:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter devices
```

For iPhone, follow the temporary build-directory procedure in
[Frontend workflow](FRONTEND_WORKFLOW.md), wait for the Dart VM service, detach,
and restore the global Flutter build-directory setting.

## Milestone acceptance matrix

| Milestone | Time | Demonstrable outcome | Approval |
| --- | --- | --- | --- |
| M0 | 0:45 | Specification, contracts, fixtures, approved baseline | Team/coordinator |
| M1 | 2:00 | Shared shell and authentication on phone | User + accessibility |
| M2 | 4:30 | Five independently tested question screens | Coordinator |
| M3 | 5:30 | Full onboarding on phone | User + accessibility |
| M4 | 8:30 | Chat, Profile, recommendations, and detail reviewed | User + reviewers |
| M5 | 10:00 | End-to-end two-tab application | Coordinator |
| M6 | 11:00 | Independent reviews resolved | Review gate |
| M7 | 12:00 | Frontend MVP demo candidate on iOS/Android, with synthetic/external dependencies clearly identified | Final user approval |

## Risk register

| Risk | Mitigation |
| --- | --- |
| Uncommitted baseline causes conflicts | Approve and commit baseline before parallel builders |
| Multiple agents edit shared files | Exclusive matrix; coordinator owns integration surfaces |
| Inconsistent onboarding UX | Build shared shell and components before question batches |
| Q2 becomes an unusable chip wall | Require semantic groups and large-text testing |
| Q3 equates travel with walking/disability | Use walking/rolling/transit framing; never derive a limit |
| Sensitive or stigmatizing copy | Function-first optional language and content review |
| Unknown becomes inaccessible | Contract enum, fixtures, tests, and independent review |
| Flutter implements scoring | Treat score/evidence as immutable contract output |
| Location denial traps the user | Just-in-time request, all permission states, manual fallback |
| Privacy overclaim | Block absolute landing claim pending approval/rewording |
| Legal copy is unavailable | Build surface only; mark placeholders non-production |
| Deletion falsely appears complete | Distinct submitted/pending/failed/confirmed states |
| Backend dependency is late | Typed interfaces and synthetic fixtures |
| Large text or motion blocks use | 3.2x and reduced-motion tests before integration |
| iPhone signing fails in Documents | Reuse documented temporary build-directory workflow |
| Time pressure expands scope | Protect Chat/Profile-only navigation and defer non-goals |

## Change control

- Requirement or scope changes must identify affected requirement IDs, phase,
  owner, dependency, tests, and timebox impact.
- The product owner approves user-visible scope changes.
- The coordinator updates this plan and the product specification together.
- A new request may replace an unstarted slice. It must not silently expand an
  active agent's ownership.
- If schedule pressure threatens the critical journey, remove an approved
  non-critical enhancement rather than weaken accessibility, privacy, evidence
  honesty, or the two-tab information architecture.
- No change may move match scoring, evidence inference, backend administration,
  legal authorship, or deletion guarantees into the Flutter client without
  explicit team authorization.
