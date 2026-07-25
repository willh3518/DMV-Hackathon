# Steering: SerpAPI as the Sole Data Source for Places, Businesses, and Reviews

This document constrains how the conversational assistant (currently `gpt-4o-mini` via the OpenAI API, per [SYSTEM_PROMPT.md](../../SYSTEM_PROMPT.md)) is allowed to obtain and use information about restaurants, other local businesses, and their reviews. It supplements — and does not override — the invariants in [AGENTS.md](../../AGENTS.md).

## Rule

**SerpAPI is the only permitted source of factual information about specific real-world places, businesses, and reviews.**

This means:

- Business existence, hours, address, phone number, price level, and category come only from a SerpAPI response returned during the current session.
- Review content, ratings, and any accessibility-relevant observations ("has a ramp," "loud after 7pm," "staff were patient") come only from review text/snippets present in a SerpAPI response.
- The model's own pretrained/parametric knowledge about specific named businesses must never be used, even if it seems plausible or the model is confident. Pretrained knowledge is not evidence — it has no source, no timestamp, and cannot be attributed to a declaring party or a reviewer.
- If SerpAPI has not been queried yet for a claim the assistant is about to make, the assistant must query it first or state that it doesn't have that information rather than answer from memory.

## Why

This directly implements two AGENTS.md invariants that are otherwise easy to violate with an LLM backend:

- **Missing evidence means unknown, never inaccessible.** A model answering from pretrained knowledge can't distinguish "I know this is inaccessible" from "I have no idea and am guessing." Restricting facts to actual SerpAPI results makes "unknown" the honest default when SerpAPI returns nothing.
- **Business-declared and customer-observed accessibility must remain distinguishable.** SerpAPI responses carry provenance (business listing fields vs. review text) that pretrained knowledge does not. Only tool output preserves that distinction.

## What SerpAPI is used for

SerpAPI is used to fetch Google Local/Maps results and Google Reviews for a given place or search query (e.g., the Google Maps/Local Pack and Reviews engines). Treat each SerpAPI call as returning two provenance-tagged categories, never merged:

| Category | Source in SerpAPI response | Evidence type |
| --- | --- | --- |
| Declared | Business listing fields (hours, category, attributes Google/the business publishes) | `declared` |
| Observed | Review text, review ratings, review timestamps | `observed` |

Every fact surfaced to the user must retain: source (declared vs. observed), recency (review/listing date if present), and — for observed evidence — enough of the original text to judge specificity and confidence. Do not discard the review snippet in favor of a paraphrase that loses attribution.

## Relevance filtering

The model must not dump raw SerpAPI results at the user. It must select and surface only the subset of returned data that is relevant to *this* user's profile and current request (their stated needs, preferences, mobility range, and interests from the intake in [SYSTEM_PROMPT.md](../../SYSTEM_PROMPT.md)). Irrelevant reviews or listing fields should be omitted, not summarized as if they were signal.

## Unknown handling

If SerpAPI returns no reviews or listing data addressing a specific accessibility attribute the user cares about (e.g., restroom maneuverability), the assistant must say that attribute is **unknown** for that place. It must never infer inaccessibility from silence, and must never infer accessibility from a place merely existing or being popular.

## Implementation notes (for whoever wires this up)

- Integrate SerpAPI as an OpenAI tool/function call (e.g., `search_places_and_reviews`) rather than pre-fetching and stuffing results into the system prompt — this keeps queries scoped to what the conversation actually needs and keeps a clear boundary between "tool result" and "model output" in the transcript.
- The SerpAPI key is a credential: keep it in the local `.env` file (gitignored), never in source, matching the OpenAI key handling already established for this project.
- Log or surface which SerpAPI call(s) backed a given answer where feasible, so evidence can be traced back to its source during review/debugging.
