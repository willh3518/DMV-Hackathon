# Version 1 Product Specification

## Document control

| Field | Value |
| --- | --- |
| Status | Draft for approval |
| Date | 2026-07-25 |
| Product name | Intentionally undecided |
| Client | Flutter mobile application for iOS and Android |
| Scope owner | Product team |
| Frontend owner | Senior frontend designer and Flutter UI engineer |
| Related guidance | [AGENTS.md](../AGENTS.md), [Frontend workflow](FRONTEND_WORKFLOW.md) |

This specification defines the Version 1 user experience and frontend contract
boundaries. It does not select a backend provider, authentication method, legal
copy, match algorithm, evidence-processing system, or final product name.

## Product summary

Version 1 is a conversational local-discovery app that helps a person find
restaurants and activities suited to their access needs, preferences, interests,
travel comfort, and ability to function in a given environment.

The core promise is:

> Help a person understand whether a nearby place may work for them, why it may
> work, and what remains uncertain.

The app personalizes recommendations from the saved profile and current
conversation. It must not reduce accessibility to one universal place rating.

## Product principles

- Accessibility is personal and must be evaluated as separate attributes.
- Missing evidence means unknown, never inaccessible.
- Business-declared and customer-observed evidence remain distinguishable.
- Personalized scores, evidence, and explanations are supplied through a
  contract; the Flutter client renders them and does not calculate them.
- Onboarding is function-first, optional, respectful, and does not require a
  diagnosis.
- Sensitive answers are skippable, reviewable, editable, and subject to account
  deletion through an external contract.
- The app itself targets WCAG 2.2 AA where applicable.
- The approved landing screen is the Version 1 visual source of truth.

## Goals and non-goals

### Goals

- Support account creation and returning-user sign-in through typed interfaces.
- Build a personalization profile through five short questions.
- Make Chat the primary place-discovery experience.
- Recommend both restaurants and activities.
- Explain strengths, concerns, evidence provenance, and uncertainty.
- Let users review and edit their profile.
- Provide Terms, Privacy, sign-out, and delete-account entry points.
- Ship a coherent, accessible light-blue experience on iOS and Android.

### Non-goals

- Selecting a final name or full brand.
- A business dashboard, public profile, social feed, or user review system.
- A map-first experience or in-app reservation/payment flow.
- Review ingestion, evidence extraction, match scoring, or ranking in Flutter.
- Backend schema, policies, secrets, infrastructure, or provider selection.
- Offline-first synchronization, production analytics, or a broad settings area.
- More than two persistent main navigation destinations.

## Assumptions and external dependencies

- Real authentication, session management, profile persistence, discovery,
  location policy, evidence, scoring, legal content, and account deletion are
  external dependencies.
- Until those dependencies are fulfilled, the frontend uses typed interfaces and
  synthetic fixtures.
- A backend response is authoritative for authentication, persistence, deletion,
  recommendation score, assessment, evidence, and confidence.
- Terms and Privacy text must be supplied and approved; the frontend team must not
  invent production legal content.
- Exact authentication fields and recovery behavior remain open.
- Location is requested just in time, has a manual fallback, and is not retained
  by default while the retention policy is unresolved.

## Information architecture

```text
Landing
|- Get started -> Sign up -> Questions 1-5 -> Main application
`- Sign in
   |- Complete profile -> Main application
   `- Incomplete profile -> Last incomplete question -> Main application

Main application
|- Chat
|  |- Recommendation cards
|  `- Place detail
`- Profile
   |- Edit profile sections
   |- Terms of Service
   |- Privacy Policy
   |- Sign out
   `- Delete account
```

Chat and Profile are the only persistent main tabs. Authentication, onboarding,
location explanation, place detail, legal documents, and confirmations are
supporting routes, sheets, or dialogs, not tabs.

## State-driven user journeys

| Journey | Required states and transitions |
| --- | --- |
| New user | Landing -> Sign up -> Q1 -> Q2 -> Q3 -> Q4 -> Q5 -> Chat |
| Returning, complete | Landing -> Sign in -> session loading -> Chat |
| Returning, incomplete | Landing -> Sign in -> session loading -> last incomplete question -> Chat after completion |
| Authentication failure | Submit -> loading -> actionable error -> retry without losing valid input |
| Signed out | Sign out confirmation -> contract confirmation -> Landing |
| Session expired | Protected screen -> session-expired notice -> Sign in; preserve only non-sensitive recoverable draft state |

Journey acceptance criteria:

- Back navigation preserves onboarding answers.
- Skip records unanswered, not a negative answer.
- A current chat request may refine matching but never silently edits the profile.
- Loading states prevent duplicate submissions.
- Screen heading focus is restored after major transitions.
- Session expiry never exposes stale protected content as an authenticated state.

## Screen inventory

| ID | Screen or surface | Purpose |
| --- | --- | --- |
| SCR-01 | Landing | Approved entry and visual reference |
| SCR-02 | Authentication | Sign up and sign in |
| SCR-03 | Question 1 | Helpful accommodations |
| SCR-04 | Question 2 | Food, service, communication, and environment preferences |
| SCR-05 | Question 3 | Travel limit without a private vehicle |
| SCR-06 | Question 4 | Interests and hobbies |
| SCR-07 | Question 5 | Situations to avoid or plan around |
| SCR-08 | Chat | Conversational discovery |
| SCR-09 | Recommendation card | Personalized result summary |
| SCR-10 | Place detail | Attribute and evidence explanation |
| SCR-11 | Profile | Profile, legal, and account controls |
| SCR-12 | Location support | Permission explanation and manual fallback |
| SCR-13 | Legal/account surfaces | Terms, Privacy, sign out, delete account |

## Authentication requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| AUTH-001 | Get started shall route to sign-up before Q1. | No unauthenticated production flow can complete profile persistence; the current direct Landing-to-Q1 prototype route is removed. |
| AUTH-002 | Sign in shall be a functional screen, not transient placeholder feedback. | The current snackbar is replaced; mode switching, Back, and Submit are keyboard and screen-reader operable. |
| AUTH-003 | Authentication shall expose default, validation, loading, failure, success, and incomplete-profile states. | Tests cover every listed state and retry preserves valid input. |
| AUTH-004 | Field and method inventory shall follow the approved external contract. | Presentation code does not name or assume a backend provider or unapproved authentication method. |
| AUTH-005 | Returning-user routing shall use session and profile-completion state. | Complete users reach Chat; incomplete users reach the last incomplete question. |
| AUTH-006 | Expired sessions shall require reauthentication. | Protected content is replaced by a clear notice and Sign-in action. |

## Onboarding requirements

### Shared behavior and semantics

The shared shell contains Back, "Question X of 5," a semantic progress indicator,
heading, explanation, selectable content, optional custom input, Skip, and
Continue.

Question semantics are:

- Q1 and Q5 capture constraint candidates.
- Q2 captures food/service/environment preferences plus any dietary requirement
  that the user explicitly identifies; Q4 captures interests and preferences.
- Q3 captures a travel limit or conditional travel response.
- Whether users explicitly classify an item as **Must have** versus **Would help**
  is an open product decision. Version 1 must not invent priority from selection
  order or wording.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| ONB-001 | Every question shall be optional. | Each has Skip; skipped is stored distinctly from None or not applicable. |
| ONB-002 | Answers shall persist while moving forward and backward. | Widget/integration tests navigate away and back with selections intact. |
| ONB-003 | Multi-select shall not auto-advance. | Continue is explicit and disabled only when an approved validation rule requires it. |
| ONB-004 | Sensitive prompts shall explain why they help and that they can be changed. | Copy is visible and semantically readable on all five questions. |
| ONB-005 | Q5 shall hand off directly to Chat when Chat is implemented, without a submit or profile-confirmation interstitial. | The frontend integration test completes Q5, opens Chat directly, and confirms that neither interstitial exists. |
| ONB-006 | Final option inventory shall remain configurable pending content approval. | No document claim treats the working list as final production copy. |

### Q1 - Accommodations

Working prompt: **What accommodations help you?**

Working categories: step-free access; wheelchair-accessible spaces; accessible
restroom; accessible parking; seating accommodations; low-vision support;
hearing or communication support; service-animal access; staff assistance;
Something else.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| Q1-001 | Q1 shall support multiple constraint candidates and an optional custom answer. | Selected/unselected semantics are announced and custom input is optional. |
| Q1-002 | Q1 shall not require a diagnosis. | No required field asks for disability or medical history. |
| Q1-003 | Q1 shall use the shared Skip action as its only decline-to-answer path. | No separate "Prefer not to say" accommodation choice is rendered; Skip remains distinct from an unanswered draft. |

### Q2 - Food, service, communication, and environment

Working prompt: **What kind of experience works best for you?**

Working groups: cuisines and food preferences; dietary requirements; table or
counter service; quieter environment; patient staff; simple or detailed
explanations; digital or large-text menus; lighting preference; lower-crowd
environment. Dietary requirements may include allergy or medical constraints
when the user explicitly supplies them. Version 1 does not independently verify
that a place is allergy-safe.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| Q2-001 | Q2 shall present grouped preference categories, not one large chip list. | Each group has a visible and semantic heading; large text does not create horizontal scrolling. |
| Q2-002 | Dietary requirements shall remain distinct from food, service, communication, and sensory preferences. | The profile and discovery contracts preserve the selected category and can display each group separately. |
| Q2-003 | Explicit allergy, medical, or other dietary requirements shall remain requirements. | The frontend does not soften an explicitly supplied requirement into a preference or claim that a place is verified allergy-safe. |
| Q2-004 | Other Q2 answers shall remain preferences unless the user-priority decision changes. | The frontend does not promote a preference to a hard constraint. |

### Q3 - Travel comfort

Working prompt: **How far are you comfortable traveling without a private vehicle?**

Working categories: a few minutes; about a quarter mile; about half a mile; about
one mile; more than one mile; It depends; no distance restriction; custom value.
Final units and option inventory remain open.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| Q3-001 | Q3 shall capture a distance, duration, conditional response, or unanswered state. | Domain validation distinguishes those states and displays units unambiguously. |
| Q3-002 | Q3 shall use walking, rolling, and transit-inclusive framing. | Copy does not infer mobility or equate travel capability only with walking. |
| Q3-003 | The app shall not derive Q3 from disability type. | No client rule maps Q1/Q5 answers to a travel limit. |

### Q4 - Interests and hobbies

Working prompt: **What kinds of places and activities interest you?**

Working categories: restaurants and cafes; museums; parks and nature; shopping;
live music; movies and theater; sports; games; arts and crafts; social
activities; family activities; Something else.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| Q4-001 | Q4 shall support multiple preferences and optional custom interests. | Restaurant and non-restaurant fixtures are both represented. |
| Q4-002 | Custom interests shall be treated as sensitive user text. | They are not logged and synthetic tests use invented values. |

### Q5 - Situations to plan around

Working prompt: **Are there situations we should avoid or plan around?**

Working categories: stairs; long periods of standing; narrow or crowded spaces;
loud environments; flashing or intense lighting; long travel distances; complex
instructions; unexpected physical contact; large crowds; limited restroom
access; None; Something else.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| Q5-001 | Q5 shall use functional situations, not require "physical and mental limitations" disclosure. | Copy review finds no diagnosis requirement or stigmatizing framing. |
| Q5-002 | None shall be mutually exclusive with constraint selections. | Selecting None clears constraints only after predictable UI feedback; tests cover both directions. |
| Q5-003 | None, Skip, and unanswered shall remain distinct. | All three are represented by separate fixture/domain states; no separate Prefer not to say option is rendered. |

## Chat requirements

Chat is the default destination after completed onboarding. It includes a greeting,
suggested restaurant and activity prompts, location context, conversation history,
message composer, and Send action.

Required states: new conversation, user message, clarification, loading, results,
no results, recoverable error, session expired, location unavailable, and service
unavailable.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| CHAT-001 | Chat shall support natural-language restaurant and activity requests. | Synthetic flows return at least one of each place type. |
| CHAT-002 | Suggested prompts shall be accessible shortcuts. | A prompt can populate or submit the composer through touch, keyboard, switch access, and screen reader. |
| CHAT-003 | Empty messages shall not submit and pending requests shall not duplicate. | Tests cover whitespace and repeated taps. |
| CHAT-004 | Errors shall preserve the user's request and offer Retry. | The request remains editable after a recoverable error. |
| CHAT-005 | Clarification shall be represented as conversation, not profile mutation. | Profile fixtures remain unchanged after a clarified request. |
| CHAT-006 | New messages and loading changes shall be announced without reading the full history again. | Semantics tests identify a bounded live-region update. |

## Recommendation-card requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| REC-001 | A card shall show place name/type, contract-supplied personalized match, concise explanation, practical context, and Details action. | Missing optional fields do not leave broken labels or spacing. |
| REC-002 | Strengths, concerns, and unknowns shall be distinct and non-color-only. | Each status has text or icon meaning and a semantic label. |
| REC-003 | The score shall be labeled as personalized, not universal accessibility. | No card uses copy equivalent to "this place is X% accessible." |
| REC-004 | Evidence summary shall expose confidence, mention count, and recency when supplied. | Partial evidence fixtures remain understandable without fabricated values. |
| REC-005 | Card actions shall meet minimum target and availability rules. | Actions are at least 48 by 48 logical pixels and unavailable actions are omitted or explained. |

## Place-detail requirements

Required states: loading, complete, partial evidence, unknown-heavy, recoverable
error, and missing external-action data.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| DET-001 | Detail shall explain the personalized result by separate accessibility attributes. | At least one strength, concern, and unknown fixture renders without collapsing into one rating. |
| DET-002 | Declared and observed evidence shall remain visibly and semantically labeled. | Agreement and disagreement fixtures preserve both sources. |
| DET-003 | Evidence shall show confidence and age when supplied and use minimal excerpts. | No development fixture contains real review or personal data. |
| DET-004 | Directions, website, call, and reservation actions shall appear only when supplied. | Missing-action fixtures do not expose dead controls. |
| DET-005 | Closing detail shall restore focus to the originating result. | A widget test verifies focus return. |
| DET-006 | A supplied external action that fails to launch shall provide actionable feedback. | Directions, call, website, and reservation failure tests preserve context and offer Retry or an available alternative such as copying the address, phone number, or link. |

## Profile requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| PROF-001 | Profile shall expose initial loading, load failure, and retry states before profile content is available. | Loading does not show fabricated profile values; a failed load provides Retry and a successful retry renders the contract-supplied profile. |
| PROF-002 | Profile shall summarize and edit all five onboarding sections. | Skipped, None, custom, and selected states render accurately. |
| PROF-003 | Save shall expose idle, loading, success, and failure states. | Failed save preserves local edits and offers Retry. |
| PROF-004 | Profile shall provide account, Terms, Privacy, sign-out, and delete-account entry points. | All are reachable by screen reader and keyboard without adding a third tab. |
| PROF-005 | Chat and Profile shall be the only persistent main tabs. | Navigation tests find exactly two persistent destinations. |

## Location requirements

Location shall be requested only when needed for a nearby-place request. The user
can decline and enter a city or area manually. Precise location is not retained
by default pending an approved policy.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| LOC-001 | The UI shall represent not requested, loading, granted, denied, permanently denied, services disabled, unavailable, and manual-location states. | Synthetic tests render every state. |
| LOC-002 | Before requesting permission, the app shall explain why location helps. | Denial leaves the discovery flow usable. |
| LOC-003 | Permanently denied and services-disabled states shall offer an appropriate settings action plus manual fallback. | A user can continue with manual city/area entry. |
| LOC-004 | Location retention shall be opt-in only after policy approval. | The frontend contract defaults to transient request context. |

## Legal and account requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| ACCT-001 | Terms and Privacy surfaces shall render approved supplied content and represent link/content loading, unavailable, failure, and retry states. | Placeholder content is explicitly marked non-production; no legal terms are invented; link/content failures provide Retry without showing stale content as current. |
| ACCT-002 | Sign out shall wait for contract confirmation. | Loading and failure states do not falsely display a signed-out success. |
| ACCT-003 | Delete account shall require explicit destructive confirmation. | The confirmation states that the request depends on the account contract. |
| ACCT-004 | Deletion success shall appear only after the contract confirms completion. | Submitted, pending, failed, cancelled, and confirmed states cannot be confused. |

## Visual and motion contract

The current landing screen is locked as the Version 1 reference: light-blue
vertical gradient, white and pale-blue surfaces, dark navy text, rounded bubbly
geometry, pill actions, blue-tinted shadows, sparse decorative bubbles, and
generous whitespace. The tone is friendly and optimistic, not childish.

Locked palette:

| Token | Value |
| --- | --- |
| Canvas top | `#F8FCFF` |
| Canvas bottom | `#E9F5FF` |
| Surface | `#FFFFFF` |
| Surface blue | `#E4F2FF` |
| Strong surface blue | `#C7E4FF` |
| Primary | `#2474C6` |
| Strong primary | `#155A9C` |
| Primary text | `#17324D` |
| Secondary text | `#536B80` |

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| VIS-001 | New screens shall use shared tokens and approved visual language. | Review finds no unapproved parallel palette or screen-level theme. |
| VIS-002 | Standard step transitions shall be about 300 ms with direction-aware fade/slide. | Back reverses direction; rapid taps cannot duplicate navigation. |
| VIS-003 | Reduced motion shall stop ambient animation and replace travel with a short settled crossfade. | Both Flutter `disableAnimations` and platform reduced-motion tests pass. |
| VIS-004 | The onboarding background shall remain visually continuous. | Question changes do not flash or replace the background. |

## Accessibility requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| A11Y-001 | Controls shall have semantic label, role, state, and value as applicable. | Automated semantics checks pass for every critical screen. |
| A11Y-002 | Controls shall target at least 48 by 48 logical pixels. | Android/iOS target guidelines pass. |
| A11Y-003 | Status shall not rely on color alone and contrast shall target WCAG 2.2 AA. | Automated contrast plus manual status review pass. |
| A11Y-004 | Critical screens shall remain usable at 3.2x text on a 320 by 568 test surface. | No clipped required content or unreachable action; scrolling is available. |
| A11Y-005 | Route and step changes shall move focus to a meaningful heading; overlays restore origin focus. | Focus tests pass for onboarding, detail, legal, and confirmation surfaces. |
| A11Y-006 | Decorative visuals shall be excluded from semantics and inactive animated screens shall be excluded from focus, input, and semantics. | The semantics tree exposes only the active experience. |
| A11Y-007 | Critical flow shall receive a real VoiceOver pass and an Android TalkBack pass when available. | Findings are recorded and release blockers resolved. |
| A11Y-008 | Every critical screen and supporting surface shall be completely operable in a logical order by keyboard and switch access. | Tests traverse all interactive controls in expected order, activate primary/secondary/destructive actions without touch, and find no keyboard or switch-access trap. |

## Privacy and safety requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| PRIV-001 | The app shall explain why sensitive profile data is requested and make it optional. | Every question offers Skip and editable review. |
| PRIV-002 | Credentials, tokens, profile answers, free text, precise location, and production records shall not be logged or committed. | Diff and logging review find no such values. |
| PRIV-003 | Development and tests shall use synthetic data only. | Fixtures are clearly fictional. |
| PRIV-004 | Landing copy shall avoid absolute privacy guarantees before the product's data handling is approved. | The qualified sentence "You control what you share and can update your answers anytime." is used; final policy and legal copy still require approval. |
| PRIV-005 | Review evidence shall be minimized. | Structured observations or short excerpts are used instead of full reviews. |

## Typed frontend contract boundaries

| Interface | Frontend responsibility |
| --- | --- |
| `AuthenticationGateway` | Create account, sign in/out, expose session state, request deletion |
| `ProfileRepository` | Load/save draft, complete onboarding, update profile sections |
| `DiscoveryGateway` | Submit conversation request, receive clarification/recommendations, load detail if needed |
| `LocationGateway` | Expose permission/service state, request permission, retrieve transient location, accept manual area |
| `ExternalActionLauncher` | Launch directions, website, call, and reservation actions |

Minimum presentation models include session state, onboarding progress, profile,
conversation message, clarification, recommendation, match explanation,
accessibility attribute assessment, evidence item/source, confidence/recency, and
external-action availability.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| CON-001 | Domain models shall remain independent from Flutter widgets and service implementations. | Contract/domain files import no presentation code. |
| CON-002 | Score, status, confidence, and evidence classification shall be contract supplied. | No client code computes or infers them. |
| CON-003 | Missing evidence shall map to unknown. | Null/absent fixture tests never render inaccessible by default. |

## Synthetic fixture coverage

The fixture suite shall include:

- authentication success, validation, failure, incomplete profile, and expired session;
- onboarding empty, partial, skipped, None, and custom answers;
- restaurant and activity results;
- declared/observed agreement and disagreement;
- strength, concern, unknown, partial evidence, and missing optional fields;
- no results, loading, retryable failure, and service unavailable;
- every location state in `LOC-001`;
- profile initial loading, load failure, retry, and loaded content;
- legal link/content loading, unavailable, failure, retry, and loaded content;
- directions, call, website, and reservation launch failure with Retry or an
  available copy/open alternative;
- account deletion submitted, pending, failed, cancelled, and confirmed.

## Unresolved decision register

| Decision | Owner | Status | Deadline |
| --- | --- | --- | --- |
| Authentication fields, recovery, and verification | TBD | Open | TBD |
| Final onboarding copy and option inventory | TBD | Open | TBD |
| Must have versus Would help priority UI | TBD | Open | TBD |
| Q3 units and travel option model | TBD | Open | TBD |
| Custom-answer input policy | TBD | Open | TBD |
| Exact in-chat location-permission trigger and approved explanatory copy | TBD | Open | TBD |
| Location retention policy beyond the fixed just-in-time request and no-retention default | TBD | Open | TBD |
| Chat-history persistence | TBD | Open | TBD |
| Match-score visual format | TBD | Open | TBD |
| Legal copy and approval owner | TBD | Open | TBD |
| Account-deletion timing and user copy | TBD | Open | TBD |
| Required demo external actions | TBD | Open | TBD |

## Known current-prototype gaps

- Authentication currently uses a synthetic gateway; real session, recovery,
  verification, and persistence behavior remain external dependencies.
- All five questions use controlled in-memory drafts. The direct Q5-to-Chat
  handoff and in-memory Profile transfer are connected, but persistence across
  launches remains an external dependency.
- Chat, Profile, recommendations, declared/observed evidence detail, explicit
  legal placeholders, sign out, and delete-account presentation are implemented
  against synthetic contracts.
- Location currently uses a clearly identified Washington, DC frontend fixture.
  Just-in-time permission, manual city/area selection, and retention policy
  remain external/product dependencies.
- Directions and call actions are synthetic launch fixtures. Approved legal
  copy, real external actions, and confirmed deletion behavior remain external
  dependencies.

## Frontend MVP demo-candidate definition of done

The frontend MVP demo candidate is ready for approval when the following
frontend criteria pass. Real authentication, persistence, discovery/scoring,
legal content, location policy, and deletion remain external dependencies until
their contracts are fulfilled; synthetic contract implementations demonstrate
the frontend flow but do not claim production readiness for those services.

- New, returning-complete, returning-incomplete, authentication-failure,
  signed-out, and session-expired journeys behave as specified.
- All five optional questions preserve state, support Skip, and retain their
  defined semantics.
- Chat demonstrates restaurant and activity discovery through typed contracts.
- Results and detail demonstrate strengths, concerns, unknowns, and
  declared/observed evidence without client-side scoring.
- Profile edits all five sections and exposes legal/account controls.
- Just-in-time location and manual fallback cover all specified states.
- Supplied external actions expose launch failure and recovery behavior.
- Chat and Profile are the only persistent tabs.
- Required loading, empty, error, partial, and success states exist.
- Format, analysis, tests, Android debug build, and physical iPhone launch pass.
- Automated accessibility checks, 3.2x text, reduced-motion tests, and assistive
  technology passes meet `A11Y-001` through `A11Y-007`.
- Independent accessibility and Flutter reviews have no unresolved release
  blockers.
- No secrets, production personal data, or generated build artifacts are added.
- Legal/privacy dependencies and any accepted open decisions are recorded.
- The product owner approves the final phone experience.
