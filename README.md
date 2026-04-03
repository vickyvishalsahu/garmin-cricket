# Cricket Scores — Garmin Widget

Live cricket scores on your wrist. A Garmin Connect IQ widget backed by a Cloudflare Worker that fetches real-time match data from [CricAPI](https://cricapi.com).

## Prerequisites

- [Node.js](https://nodejs.org/) (v18+) and [pnpm](https://pnpm.io/)
- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v6.x+) — install via the SDK Manager
- Java runtime (`brew install --cask temurin`)
- A developer key (generate once):
  ```bash
  openssl genrsa 4096 | openssl pkcs8 -topk8 -nocrypt -outform DER -out "$HOME/Library/Application Support/Garmin/ConnectIQ/developer_key.der"
  ```

## Running Locally

### 1. Start the Worker (`worker/`)

```bash
cd worker
pnpm install
pnpm dev
```

Set up secrets and KV (first time only):
```bash
pnpm exec wrangler secret put CRICAPI_KEY
pnpm exec wrangler kv namespace create SCORE_CACHE
```
Update `wrangler.toml` with the KV namespace ID.

### 2. Start the Watch Simulator (`watch/`)

```bash
cd watch
make sim          # Launch the simulator
make run          # Build and load the app
```

Other commands:
```bash
make build              # Compile only
make clean              # Remove build output
make run DEVICE=venu2   # Target a different device
```

### Testing without a CricAPI key

The worker has a mock endpoint:
```bash
curl "http://localhost:8787/mock?team=IND_M&mode=live"
curl "http://localhost:8787/mock?team=IND_M&mode=completed"
```
