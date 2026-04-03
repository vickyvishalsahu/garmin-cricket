# Cricket Scores — Garmin Widget

## Repo structure

```
worker/     ← Cloudflare Worker (JS, Wrangler)
watch/      ← Garmin Connect IQ widget (Monkey C) — not yet built
```

## Worker quick reference

- `cd worker && wrangler dev` for local dev (http://localhost:8787)
- `wrangler deploy` to publish
- Test: `curl "http://localhost:8787/score?team=IND_M"`
- Secrets: `CRICAPI_KEY` (set via `wrangler secret put`)
- KV namespace: `SCORE_CACHE` (update `wrangler.toml` with real ID after creation)

## Response contract

The watch app depends on the exact JSON shape returned by `/score?team=X`.
Do not rename or remove keys without updating the watch app.
