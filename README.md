# Cricket Scores — Garmin Widget

Live cricket scores on your wrist. A Garmin Connect IQ widget backed by a Cloudflare Worker that fetches real-time match data from [CricAPI](https://cricapi.com).

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Supported Teams](#supported-teams)
- [Supported Devices](#supported-devices)
- [Repository Structure](#repository-structure)
- [Cloudflare Worker](#cloudflare-worker)
  - [Prerequisites](#worker-prerequisites)
  - [Setup](#worker-setup)
  - [API Reference](#api-reference)
  - [Response Format](#response-format)
  - [Caching Strategy](#caching-strategy)
  - [Mock Endpoint](#mock-endpoint)
- [Garmin Watch Widget](#garmin-watch-widget)
  - [Prerequisites](#watch-prerequisites)
  - [Building](#building)
  - [Widget Settings](#widget-settings)
  - [How It Works](#how-it-works)
  - [Display Screens](#display-screens)
- [Data Flow](#data-flow)
- [Release Process](#release-process)
- [Development Workflow](#development-workflow)

---

## Overview

This project has two components that work together:

1. **Cloudflare Worker** (`worker/`) — A lightweight API proxy that sits between the watch and CricAPI. It fetches current matches, filters by team, normalises the response into a compact format suitable for a watch screen, and caches results in Cloudflare KV to stay within API rate limits.

2. **Garmin Connect IQ Widget** (`watch/`) — A Monkey C widget that runs on Garmin watches. It calls the Worker API on a schedule (every 10 minutes in the background, every 2 minutes in the foreground) and renders live or completed match information on the watch face.

---

## Architecture

```
┌──────────────┐    HTTP/JSON     ┌─────────────────────┐    HTTPS/JSON    ┌──────────┐
│  Garmin Watch │ ──────────────► │  Cloudflare Worker   │ ───────────────► │  CricAPI │
│  (Connect IQ) │ ◄────────────── │  + KV Cache          │ ◄─────────────── │          │
└──────────────┘   compact JSON   └─────────────────────┘   raw match data └──────────┘
```

The Worker acts as:
- **API proxy** — hides the CricAPI key from the watch
- **Normaliser** — transforms verbose CricAPI responses into a compact, watch-friendly format
- **Cache layer** — reduces CricAPI calls via Cloudflare KV with match-state-aware TTLs

---

## Supported Teams

Both the Worker and watch support 18 international teams. The team code is used as the `?team=` query parameter:

| Code | Team | Code | Team |
|------|------|------|------|
| `IND_M` | India Men | `IND_W` | India Women |
| `AUS_M` | Australia Men | `AUS_W` | Australia Women |
| `ENG_M` | England Men | `ENG_W` | England Women |
| `NZ_M` | New Zealand Men | `NZ_W` | New Zealand Women |
| `SA_M` | South Africa Men | `SA_W` | South Africa Women |
| `PAK_M` | Pakistan Men | `PAK_W` | Pakistan Women |
| `SL_M` | Sri Lanka Men | `WI_M` | West Indies Men |
| `BAN_M` | Bangladesh Men | `AFG_M` | Afghanistan Men |
| `ZIM_M` | Zimbabwe Men | `IRE_M` | Ireland Men |

---

## Supported Devices

The widget targets the following Garmin devices (Connect IQ API level 3.2.0+):

- Fenix 7 / 7S / 7X
- Epix 2 (Gen 2)
- Venu 2 / 2S
- Venu 3 / 3S
- Vivoactive 5
- Forerunner 265 / 265S / 965

---

## Repository Structure

```
├── worker/                     Cloudflare Worker (JavaScript)
│   ├── src/
│   │   ├── index.js            Entry point — request routing, mock endpoint
│   │   ├── cricapi.js          CricAPI HTTP client
│   │   ├── normalise.js        Transforms raw API data → compact match format
│   │   ├── cache.js            KV cache get/set with state-aware TTLs
│   │   └── teams.js            Team code → CricAPI name mapping
│   ├── wrangler.toml           Wrangler configuration (KV binding, etc.)
│   └── package.json            Dependencies (wrangler)
│
├── watch/                      Garmin Connect IQ Widget (Monkey C)
│   ├── source/
│   │   ├── CricketApp.mc       App lifecycle, background registration, settings
│   │   ├── CricketView.mc      Main UI — renders live/completed/no-data screens
│   │   ├── CricketBackground.mc  Background service delegate for scheduled fetches
│   │   ├── CricketDelegate.mc  Input handling (select to refresh, swipe for settings hint)
│   │   ├── SettingsHintView.mc  "Change team in Garmin Connect" hint screen
│   │   └── Teams.mc            Team code array (index-based lookup from settings)
│   ├── resources/
│   │   ├── settings/
│   │   │   ├── settings.xml    User-facing settings (team picker, worker URL)
│   │   │   └── properties.xml  Default property values
│   │   ├── strings/strings.xml Localised strings
│   │   └── drawables/          Launcher icon
│   ├── manifest.xml            App ID, permissions, supported devices
│   └── monkey.jungle           Build configuration
│
├── release                     Release automation script (bash)
├── CLAUDE.md                   Project instructions for Claude Code
└── .gitignore                  Excludes watch/bin/, worker/.wrangler/, etc.
```

---

## Cloudflare Worker

### Worker Prerequisites

- [Node.js](https://nodejs.org/) (v18+)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) (v3+)
- A [CricAPI](https://cricapi.com) account and API key
- A Cloudflare account

### Worker Setup

1. **Install dependencies:**
   ```bash
   cd worker
   pnpm install
   ```

2. **Create a KV namespace:**
   ```bash
   wrangler kv namespace create SCORE_CACHE
   ```
   Copy the output `id` into `wrangler.toml`:
   ```toml
   [[kv_namespaces]]
   binding = "SCORE_CACHE"
   id = "<your-namespace-id>"
   ```

3. **Set the API key secret:**
   ```bash
   wrangler secret put CRICAPI_KEY
   ```
   Paste your CricAPI key when prompted.

4. **Run locally:**
   ```bash
   pnpm dev
   # or: wrangler dev
   ```
   The Worker starts at `http://localhost:8787`.

5. **Test:**
   ```bash
   curl "http://localhost:8787/score?team=IND_M"
   ```

6. **Deploy to Cloudflare:**
   ```bash
   pnpm deploy
   # or: wrangler deploy
   ```

### API Reference

#### `GET /score?team=<TEAM_CODE>`

Returns the current or most recent match for the specified team.

**Query Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `team` | Yes | Team code from the [supported teams](#supported-teams) table |

**Status Codes:**

| Code | Description |
|------|-------------|
| `200` | Success — match found or no match found (check `found` field) |
| `400` | Invalid or missing `team` parameter |
| `404` | Unknown route (only `/score` is valid) |
| `502` | Upstream CricAPI fetch failed |

**Match Selection Logic:**
When multiple matches exist for a team, the Worker prefers **live** matches over completed ones. If no live match is found, the most recent match is returned.

#### `OPTIONS /score`

Returns CORS preflight headers. The Worker allows all origins (`*`).

### Response Format

All responses share this top-level envelope:

```json
{
  "team": "IND_M",
  "found": true,
  "match": { ... },
  "cachedAt": 1711843200
}
```

| Field | Type | Description |
|-------|------|-------------|
| `team` | `string` | The requested team code |
| `found` | `boolean` | Whether a match was found for this team |
| `match` | `object \| null` | Match data (null when `found` is false) |
| `cachedAt` | `number` | Unix timestamp when the response was generated/cached |

#### Live Match

When `match.status` is `"live"`:

```json
{
  "status": "live",
  "type": "t20",
  "opponent": "AUS",
  "batting": {
    "team": "IND",
    "runs": 142,
    "wickets": 3,
    "overs": "14.2"
  },
  "crr": 9.9,
  "rrr": 10.4,
  "target": 188,
  "result": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status` | `string` | `"live"` |
| `type` | `string` | Match format: `"t20"`, `"odi"`, `"test"`, or `"other"` |
| `opponent` | `string` | Short code of the opposing team |
| `batting` | `object` | Current batting team's score |
| `batting.team` | `string` | Short code of the batting team |
| `batting.runs` | `number` | Runs scored |
| `batting.wickets` | `number` | Wickets fallen |
| `batting.overs` | `string` | Overs bowled (e.g. `"14.2"`) |
| `crr` | `number \| null` | Current run rate |
| `rrr` | `number \| null` | Required run rate (2nd innings of limited-overs only) |
| `target` | `number \| null` | Target score (2nd innings only) |
| `result` | `null` | Always null for live matches |

#### Completed Match

When `match.status` is `"completed"`:

```json
{
  "status": "completed",
  "type": "odi",
  "opponent": "ENG",
  "innings": [
    { "team": "ENG", "runs": 287, "wickets": 8, "overs": "50.0" },
    { "team": "IND", "runs": 291, "wickets": 5, "overs": "47.3" }
  ],
  "result": "IND won by 5 wkts",
  "crr": null,
  "rrr": null,
  "target": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status` | `string` | `"completed"` |
| `type` | `string` | Match format |
| `opponent` | `string` | Short code of the opposing team |
| `innings` | `array` | Array of innings (up to 4 for Tests) |
| `innings[].team` | `string` | Short code of the batting team for that innings |
| `innings[].runs` | `number` | Runs scored |
| `innings[].wickets` | `number` | Wickets fallen |
| `innings[].overs` | `string` | Overs bowled |
| `result` | `string` | Result string (e.g. `"IND won by 5 wkts"`) |

### Caching Strategy

The Worker caches responses in Cloudflare KV with match-state-aware TTLs to balance freshness against CricAPI rate limits:

| Match State | TTL | Rationale |
|-------------|-----|-----------|
| **Live** | 120 seconds (2 min) | Scores change frequently during play |
| **Completed** | 300 seconds (5 min) | Result is final, less urgency |
| **Not found** | 60 seconds (1 min) | Re-check soon in case a match starts |

Cache keys follow the pattern `score:<TEAM_CODE>` (e.g. `score:IND_M`).

### Mock Endpoint

A mock endpoint is available for simulator testing without needing a CricAPI key:

```bash
# Live match mock
curl "http://localhost:8787/mock?team=IND_M&mode=live"

# Completed match mock
curl "http://localhost:8787/mock?team=IND_M&mode=completed"

# No match mock
curl "http://localhost:8787/mock?team=IND_M&mode=none"
```

The `mode` parameter controls the response:
- `live` — Returns a simulated live T20 match (IND 142/3 in 14.2 overs, chasing 188)
- `completed` — Returns a simulated completed ODI (IND beat ENG by 5 wickets)
- Any other value — Returns `found: false`

---

## Garmin Watch Widget

### Watch Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v6.x+ recommended)
- A compatible Garmin device or the Connect IQ Simulator
- [Visual Studio Code](https://code.visualstudio.com/) with the [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c) (recommended)

### Building

1. Open the `watch/` folder in VS Code with the Monkey C extension installed.
2. Set the SDK path in the extension settings.
3. Select a target device (e.g. `fenix7`).
4. Build and run in the simulator via the extension's command palette (`Monkey C: Build for Device` or `Ctrl+F5`).

Alternatively, build from the command line:
```bash
monkeyc -f watch/monkey.jungle -d fenix7 -o watch/bin/CricketScores.prg
```

### Widget Settings

Users configure the widget via the **Garmin Connect** mobile app (or Garmin Express on desktop). Two settings are available:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| **Team** | List picker | India Men (index 0) | Select which international team to follow |
| **Worker URL** | Text input | `http://localhost:8787` | Base URL of the deployed Cloudflare Worker |

After changing the team, cached match data is automatically cleared and the widget refreshes.

### How It Works

The widget uses two fetch mechanisms:

#### Background Fetch (every 10 minutes)
- Registered via `Background.registerForTemporalEvent` on app start
- The `CricketBackground` service delegate makes an HTTP request to the Worker's `/score` endpoint
- Response data is passed back to the main app via `Background.exit()` → `onBackgroundData()`
- Data is persisted to `Storage` so it survives app restarts

#### Foreground Fetch (every 2 minutes)
- A `Timer` fires every 2 minutes while the widget is visible
- Makes a direct HTTP request from `CricketView`
- Currently configured to hit the `/mock` endpoint for simulator testing
- Updates `Storage` and triggers a screen redraw

#### Manual Refresh
- Press the **select** button (middle button on most devices) to trigger an immediate fetch

### Display Screens

The widget has four display states:

#### 1. Live Match
```
         LIVE
     IND v AUS · T20

       IND batting
         142/3
        (14.2)

    CRR 9.90  RRR 10.40
       Target: 188

          2m ago
```
- Red **LIVE** indicator at the top
- Match header: `<YOUR_TEAM> v <OPPONENT> · <FORMAT>`
- Current batting team's score: runs/wickets with overs
- Run rates: current run rate (CRR) and required run rate (RRR)
- Chase target (shown in 2nd innings)
- Footer: age of cached data

#### 2. Completed Match
```
     IND v ENG · ODI

   ENG  287/8 (50.0)
   IND  291/5 (47.3)

    IND won by 5 wkts

          5m ago
```
- Match header
- Each innings listed with team, runs/wickets, overs (up to 4 innings for Tests)
- Result string in yellow
- Footer: age of cached data

#### 3. No Recent Matches
```
          IND
    No recent matches
```
- Shows team code and a "No recent matches" message in grey

#### 4. Loading
```
          IND
        Loading...
```
- Displayed before the first data fetch completes

#### Settings Hint Screen
Swiping down (or pressing the down button) shows a hint:
```
     Change team in
    Garmin Connect app
```
This directs users to the mobile app to change settings, since widgets cannot render settings UI on-device.

---

## Data Flow

```
1. User selects team "IND_M" in Garmin Connect app
2. Widget reads TeamIndex property → Teams.getCode(0) → "IND_M"
3. Background timer fires every 10 minutes
4. CricketBackground calls: GET <WorkerUrl>/score?team=IND_M
5. Worker checks KV cache for key "score:IND_M"
   a. Cache HIT → return cached JSON immediately
   b. Cache MISS:
      i.   Call CricAPI /v1/currentMatches
      ii.  Filter matches where teams[] includes "India"
      iii. Prefer live match over completed
      iv.  Normalise into compact format (runs, wickets, overs, rates)
      v.   Store in KV with appropriate TTL (120s live / 300s completed)
      vi.  Return JSON
6. Watch receives JSON, stores in Application.Storage
7. CricketView.onUpdate() reads Storage and draws the appropriate screen
8. Footer shows "Xm ago" based on lastFetch timestamp
```

---

## Release Process

The repository includes a `release` script that automates merging `dev` → `main`, tagging, and creating GitHub releases.

**Usage:**
```bash
./release              # Release dev → main
./release --dry-run    # Simulate without making changes
./release --force      # Allow releasing when local is ahead of origin
```

**What it does:**
1. Fetches latest changes from origin
2. Validates local branch is in sync with remote
3. Shows a diff of commits to be released
4. Prompts for confirmation
5. Merges the source branch into `main`
6. Creates an auto-incrementing tag (`v1`, `v2`, ...)
7. Creates a GitHub Release (if `gh` CLI is installed)
8. Merges `main` back into `dev`
9. Returns to the `dev` branch on exit

**Options:**

| Flag | Description |
|------|-------------|
| `--dry-run`, `-d` | Simulate without making any changes |
| `--force`, `-f` | Proceed even if local branch is ahead of origin |
| `--source <branch>` | Override the source branch (default: `dev`) |
| `--target <branch>` | Override the target branch (default: `main`) |
| `--develop <branch>` | Override the develop branch (default: source branch) |
| `--env <file>`, `-e` | Load custom environment variables from a file |
| `--debug` | Enable bash debug mode (`set -x`) |
| `--version`, `-v` | Print version |
| `--help`, `-h` | Print help |

---

## Development Workflow

1. **All work happens on `dev`** — never commit directly to `main`.
2. Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `chore:`, `docs:`, `ref:`, etc.
3. Use `./release` to promote `dev` to `main` when ready.
4. The Worker and watch can be developed independently — they communicate only via the JSON contract documented in [Response Format](#response-format).

**Important:** Do not rename or remove keys from the Worker's JSON response without updating the watch app, as the widget depends on the exact shape.
