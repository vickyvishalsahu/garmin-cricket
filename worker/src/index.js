import { TEAM_MAP } from "./teams.js";
import { fetchCurrentMatches } from "./cricapi.js";
import { normalise } from "./normalise.js";
import { getCache, setCache } from "./cache.js";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);

    // Mock endpoint for simulator testing (remove before production)
    if (url.pathname === "/mock") {
      const team = url.searchParams.get("team") || "IND_M";
      const mode = url.searchParams.get("mode") || "live";
      return json(mockData(team, mode));
    }

    if (url.pathname !== "/score") {
      return json({ error: "Not found" }, 404);
    }

    const teamCode = url.searchParams.get("team");
    if (!teamCode || !TEAM_MAP[teamCode]) {
      return json({ error: "Invalid team. Valid codes: " + Object.keys(TEAM_MAP).join(", ") }, 400);
    }

    // Check cache
    const cached = await getCache(env.SCORE_CACHE, teamCode);
    if (cached) {
      return json(cached);
    }

    // Fetch fresh data
    try {
      const matches = await fetchCurrentMatches(env.CRICAPI_KEY);
      const team = TEAM_MAP[teamCode];

      // Find the team's match — prefer live over completed
      const teamMatches = matches.filter(
        (m) => m.teams && m.teams.includes(team.apiName)
      );

      let bestMatch = null;
      for (const m of teamMatches) {
        const isLive = m.matchStarted === true && m.matchEnded === false;
        if (isLive) {
          bestMatch = m;
          break;
        }
        if (!bestMatch) bestMatch = m;
      }

      let data;
      if (bestMatch) {
        const normalised = normalise(bestMatch, teamCode);
        data = {
          team: teamCode,
          found: true,
          match: normalised,
          cachedAt: Math.floor(Date.now() / 1000),
        };
      } else {
        data = {
          team: teamCode,
          found: false,
          match: null,
          cachedAt: Math.floor(Date.now() / 1000),
        };
      }

      await setCache(env.SCORE_CACHE, teamCode, data);
      return json(data);
    } catch (err) {
      console.error("Upstream error:", err);
      return json({ error: "Upstream fetch failed", detail: err.message }, 502);
    }
  },
};

function mockData(team, mode) {
  if (mode === "live") {
    return {
      team,
      found: true,
      match: {
        status: "live",
        type: "t20",
        opponent: "AUS",
        batting: { team: "IND", runs: 142, wickets: 3, overs: "14.2" },
        crr: 9.9,
        rrr: 10.4,
        target: 188,
        result: null,
      },
      cachedAt: Math.floor(Date.now() / 1000),
    };
  }
  if (mode === "completed") {
    return {
      team,
      found: true,
      match: {
        status: "completed",
        type: "odi",
        opponent: "ENG",
        innings: [
          { team: "ENG", runs: 287, wickets: 8, overs: "50.0" },
          { team: "IND", runs: 291, wickets: 5, overs: "47.3" },
        ],
        result: "IND won by 5 wkts",
        crr: null,
        rrr: null,
        target: null,
      },
      cachedAt: Math.floor(Date.now() / 1000),
    };
  }
  return {
    team,
    found: false,
    match: null,
    cachedAt: Math.floor(Date.now() / 1000),
  };
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS,
    },
  });
}
