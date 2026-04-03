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
pnpm exec wrangler secret put CRICAPI_KEY
```

Create a KV namespace and update `wrangler.toml` with the ID:
```bash
pnpm exec wrangler kv namespace create SCORE_CACHE
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

Requires:
- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v6.x+) — install via the SDK Manager
- Java runtime (`brew install --cask temurin`)
- A developer key (generate once):
  ```bash
  openssl genrsa 4096 | openssl pkcs8 -topk8 -nocrypt -outform DER -out "$HOME/Library/Application Support/Garmin/ConnectIQ/developer_key.der"
  ```

From the `watch/` folder:
```bash
make sim          # 1. Launch the simulator
make run          # 2. Build and load the app
```

Other commands:
```bash
make build        # Compile only
make clean        # Remove build output
make run DEVICE=venu2   # Target a different device
```
