# Chat spike proxy

A minimal, dependency-free Dart server that holds `OPENAI_API_KEY` and `SERPAPI_API_KEY` so the Flutter client (`../app`) never ships either key in its bundle. It also sidesteps SerpAPI's CORS restriction, which otherwise blocks direct browser-origin requests to `serpapi.com` on Flutter Web.

This stands in for what should eventually be a Supabase Edge Function per the planned stack in [AGENTS.md](../AGENTS.md) — it exists now to unblock local development without provisioning Supabase.

## Endpoints

- `POST /api/chat` — forwards the request body verbatim to OpenAI's `chat/completions`, with the `Authorization` header attached server-side.
- `GET /api/places?q=<query>` — forwards to SerpAPI's Google Local engine (`engine=google_local`) with the API key attached server-side.

## Setup

1. Copy `.env.example` to `.env` and fill in both keys.
2. Run:

   ```
   dart run bin/server.dart
   ```

3. It listens on `http://localhost:8787`. Start this before running the Flutter app in `../app`.
