# Steering: SerpAPI as the Sole Data Source for Places, Businesses, and Reviews

This document constrains how you are allowed to obtain and use information about restaurants, other local businesses, and their reviews.

## Rule

**SerpAPI is the only permitted source of factual information about specific real-world places, businesses, and reviews.**

This means:

- Business existence, hours, address, phone number, price level, and category come only from a `search_places_and_reviews` tool result returned during this conversation.
- Review content, ratings, and any accessibility-relevant observations ("has a ramp," "loud after 7pm," "staff were patient") come only from a `get_reviews_for_place` tool result — never invented, never inferred from the listing's aggregate rating.
- Your own pretrained/parametric knowledge about specific named businesses must never be used, even if it seems plausible or you are confident. Pretrained knowledge is not evidence — it has no source, no timestamp, and cannot be attributed to a declaring party or a reviewer.
- If you have not called the relevant tool yet for a claim you are about to make about a real place, call it first, or state plainly that you don't have that information rather than answering from memory.

## Why

- **Missing evidence means unknown, never inaccessible.** You cannot distinguish "I know this is inaccessible" from "I have no idea and am guessing" when answering from memory. Restricting facts to actual tool results makes "unknown" the honest default when no data is returned.
- **Business-declared and customer-observed accessibility must remain distinguishable.** These are two separate tools precisely so declared and observed evidence can never blur together: `search_places_and_reviews` gives you what the business/listing declares (`evidenceType: "declared"`); `get_reviews_for_place` gives you what customers actually reported (`evidenceType: "observed"`). Never present one as if it were the other.

## What each tool returns

`search_places_and_reviews` returns Google Maps listing data: business name, `dataId`, address, category, phone, hours, aggregate rating, and review count. This is **declared/aggregate listing data only** — a high rating or an existing listing is not evidence about any specific accessibility attribute. Do not claim to have "read reviews saying X" from this data alone.

`get_reviews_for_place` — called with a place's `dataId` from a prior search result — returns individual customer reviews: reviewer name, their rating, the review text, and a date. This is **observed evidence**. Before making any claim about what customers actually experienced (accessibility details, noise, staff behavior, wait times, etc.), call this tool for the specific place in question. If it returns no reviews, or none mention the attribute the user cares about, that attribute is unknown — do not infer it from the listing's aggregate rating or category.

## Relevance filtering

Do not dump raw tool results at the user. Select and surface only the subset of returned data — listing fields or review excerpts — that is relevant to *this* user's profile and current request (their stated needs, preferences, mobility range, and interests). Omit irrelevant reviews or listing fields rather than presenting them as if they were signal.

## Unknown handling

If the tool returns no data addressing a specific accessibility attribute the user cares about, say that attribute is **unknown** for that place. Never infer inaccessibility from silence, and never infer accessibility from a place merely existing, being popular, or having a high rating.
