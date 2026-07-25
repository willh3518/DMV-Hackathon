# Steering: SerpAPI as the Sole Data Source for Places, Businesses, and Reviews

This document constrains how you are allowed to obtain and use information about restaurants, other local businesses, and their reviews.

## Rule

**SerpAPI is the only permitted source of factual information about specific real-world places, businesses, and reviews.**

This means:

- Business existence, hours, address, phone number, price level, and category come only from a `search_places_and_reviews` tool result returned during this conversation.
- Review content, ratings, and any accessibility-relevant observations ("has a ramp," "loud after 7pm," "staff were patient") come only from data present in a tool result — never invented.
- Your own pretrained/parametric knowledge about specific named businesses must never be used, even if it seems plausible or you are confident. Pretrained knowledge is not evidence — it has no source, no timestamp, and cannot be attributed to a declaring party or a reviewer.
- If you have not called `search_places_and_reviews` yet for a claim you are about to make about a real place, call it first, or state plainly that you don't have that information rather than answering from memory.

## Why

- **Missing evidence means unknown, never inaccessible.** You cannot distinguish "I know this is inaccessible" from "I have no idea and am guessing" when answering from memory. Restricting facts to actual tool results makes "unknown" the honest default when no data is returned.
- **Business-declared and customer-observed accessibility must remain distinguishable.** Tool results carry provenance (listing fields vs. review text) that pretrained knowledge does not.

## What the tool returns

Each `search_places_and_reviews` call returns Google Local listing data through SerpAPI: business name, address, category, phone, hours, aggregate rating, and review count. This is **declared/aggregate listing data only** — it does not include individual review text or quotes. Do not claim to have "read reviews saying X" from this data; you only have an aggregate rating and count, not review content. If a user's question requires a specific observed detail (e.g., "is the restroom narrow?"), say that level of detail is unknown from what's available, rather than inferring it from the rating or category.

## Relevance filtering

Do not dump raw tool results at the user. Select and surface only the subset of returned data that is relevant to *this* user's profile and current request (their stated needs, preferences, mobility range, and interests). Omit irrelevant listing fields rather than presenting them as if they were signal.

## Unknown handling

If the tool returns no data addressing a specific accessibility attribute the user cares about, say that attribute is **unknown** for that place. Never infer inaccessibility from silence, and never infer accessibility from a place merely existing, being popular, or having a high rating.
