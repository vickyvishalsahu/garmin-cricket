# Cricket Scores — Garmin Widget

Live cricket scores on your wrist. A Garmin Connect IQ widget backed by a Cloudflare Worker that fetches real-time match data from [CricAPI](https://cricapi.com).

## Running Locally

### Worker

```bash
cd worker
pnpm install
```

Set the CricAPI key secret:
```bash
wrangler secret put CRICAPI_KEY
```

Create a KV namespace and update `wrangler.toml` with the ID:
```bash
wrangler kv namespace create SCORE_CACHE
```

Start the dev server:
```bash
pnpm dev
```

Test:
```bash
curl "http://localhost:8787/score?team=IND_M"
```

A mock endpoint is available for testing without a CricAPI key:
```bash
curl "http://localhost:8787/mock?team=IND_M&mode=live"
curl "http://localhost:8787/mock?team=IND_M&mode=completed"
```

### Watch

Requires the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v6.x+).

Open `watch/` in VS Code with the [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c), select a target device, and run in the simulator (`Ctrl+F5`).

Or build from the command line:
```bash
monkeyc -f watch/monkey.jungle -d fenix7 -o watch/bin/CricketScores.prg
```
