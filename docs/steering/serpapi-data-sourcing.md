# Steering: SerpAPI as the Sole Data Source for Places, Businesses, and Reviews

This document constrains how the conversational assistant (currently `gpt-4o` via the OpenAI API, per [SYSTEM_PROMPT.md](../../SYSTEM_PROMPT.md)) is allowed to obtain and use information about restaurants, other local businesses, and their reviews. It supplements — and does not override — the invariants in [AGENTS.md](../../AGENTS.md).

## Rule

**SerpAPI is the only permitted source of factual information about specific real-world places, businesses, and reviews.**

This means:

- Business existence, hours, address, phone number, price level, and category come only from a `search_places_and_reviews` tool result returned during the current session.
- Review content, ratings, and any accessibility-relevant observations ("has a ramp," "loud after 7pm," "staff were patient") come only from a `get_reviews_for_place` tool result — never invented, never inferred from the listing's aggregate rating.
- The model's own pretrained/parametric knowledge about specific named businesses must never be used, even if it seems plausible or the model is confident. Pretrained knowledge is not evidence — it has no source, no timestamp, and cannot be attributed to a declaring party or a reviewer.
- If the relevant tool has not been queried yet for a claim the assistant is about to make, the assistant must query it first or state that it doesn't have that information rather than answer from memory.

## Why

This directly implements two AGENTS.md invariants that are otherwise easy to violate with an LLM backend:

- **Missing evidence means unknown, never inaccessible.** A model answering from pretrained knowledge can't distinguish "I know this is inaccessible" from "I have no idea and am guessing." Restricting facts to actual tool results makes "unknown" the honest default when nothing is returned.
- **Business-declared and customer-observed accessibility must remain distinguishable.** This is implemented as two separate tools rather than one, so declared and observed evidence can never blur together at the source.

## What each tool is used for

Two SerpAPI-backed tools, each returning one provenance-tagged evidence category, never merged:

| Tool | SerpAPI engine | Returns | Evidence type |
| --- | --- | --- | --- |
| `search_places_and_reviews` | `google_maps` | Business name, `dataId`, address, category, phone, hours, aggregate rating, review count | `declared` |
| `get_reviews_for_place` | `google_maps_reviews` (needs the `dataId` from a prior search) | Individual reviews: reviewer name, their rating, review text, date | `observed` |

Every fact surfaced to the user must retain: source (declared vs. observed), recency (review/listing date if present), and — for observed evidence — enough of the original text to judge specificity and confidence. Do not discard the review snippet in favor of a paraphrase that loses attribution.

Note: `search_places_and_reviews`'s `place_id`-like identifiers are not interchangeable across SerpAPI engines — `google_maps_reviews` specifically requires the `dataId` field from a `google_maps` search result, not SerpAPI's `place_id`/`data_cid`. Verify field names live against the actual API response before changing either engine; the shapes differ per engine and have changed once already during this project (`engine=google` vs `engine=google_maps` nest `local_results` differently).

## Relevance filtering

The model must not dump raw tool results at the user. It must select and surface only the subset of returned data — listing fields or review excerpts — that is relevant to *this* user's profile and current request (their stated needs, preferences, mobility range, and interests from the intake in [SYSTEM_PROMPT.md](../../SYSTEM_PROMPT.md)). Irrelevant reviews or listing fields should be omitted, not summarized as if they were signal.

## Unknown handling

If neither tool returns data addressing a specific accessibility attribute the user cares about (e.g., restroom maneuverability), the assistant must say that attribute is **unknown** for that place. It must never infer inaccessibility from silence, and must never infer accessibility from a place merely existing, being popular, or having a high aggregate rating.

## Implementation notes (for whoever wires this up)

- Integrate SerpAPI as OpenAI tool/function calls (`search_places_and_reviews`, `get_reviews_for_place`) rather than pre-fetching and stuffing results into the system prompt — this keeps queries scoped to what the conversation actually needs and keeps a clear boundary between "tool result" and "model output" in the transcript.
- Both SerpAPI and OpenAI are called through a local proxy (`server/`), not directly from the Flutter client: SerpAPI does not send CORS headers permitting browser-origin requests, and neither key should ship inside a client bundle (web or mobile).
- The SerpAPI and OpenAI keys are credentials: keep them in `server/.env` (gitignored), never in source and never in the Flutter client.
- Log or surface which tool call(s) backed a given answer where feasible, so evidence can be traced back to its source during review/debugging.
