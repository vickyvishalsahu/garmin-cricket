import { TEAM_MAP } from "./teams.js";

export function normalise(match, teamCode) {
  const team = TEAM_MAP[teamCode];
  const isCompleted = match.matchStarted === true && match.matchEnded === true;
  const isLive = match.matchStarted === true && match.matchEnded === false;

  const opponent = findOpponent(match.teams, team.apiName);
  const type = detectType(match.matchType);

  if (isCompleted) {
    return {
      status: "completed",
      type,
      opponent,
      innings: buildInnings(match.score),
      result: match.status || null,
      crr: null,
      rrr: null,
      target: null,
    };
  }

  if (isLive) {
    const current = currentInnings(match.score);
    return {
      status: "live",
      type,
      opponent,
      batting: current,
      crr: parseFloat(current.overs) > 0
        ? parseFloat((current.runs / parseFloat(current.overs)).toFixed(1))
        : null,
      rrr: calcRRR(match, current),
      target: calcTarget(match),
      result: null,
    };
  }

  return null;
}

function findOpponent(teams, apiName) {
  if (!teams || teams.length < 2) return "TBD";
  const opp = teams.find((t) => t !== apiName);
  // Shorten to code if we have it, otherwise use first 3 chars
  for (const [code, val] of Object.entries(TEAM_MAP)) {
    if (val.apiName === opp) return code.replace(/_[MW]$/, "");
  }
  return opp ? opp.substring(0, 3).toUpperCase() : "TBD";
}

function detectType(matchType) {
  if (!matchType) return "other";
  const t = matchType.toLowerCase();
  if (t === "t20" || t === "t20i") return "t20";
  if (t === "odi") return "odi";
  if (t === "test") return "test";
  return "other";
}

function buildInnings(scoreArr) {
  if (!scoreArr || scoreArr.length === 0) return [];
  return scoreArr.map((s) => ({
    team: shortenTeamName(s.inning),
    runs: s.r,
    wickets: s.w,
    overs: String(s.o),
  }));
}

function currentInnings(scoreArr) {
  if (!scoreArr || scoreArr.length === 0) {
    return { team: "?", runs: 0, wickets: 0, overs: "0.0" };
  }
  const last = scoreArr[scoreArr.length - 1];
  return {
    team: shortenTeamName(last.inning),
    runs: last.r,
    wickets: last.w,
    overs: String(last.o),
  };
}

function shortenTeamName(inningStr) {
  if (!inningStr) return "?";
  // inningStr is like "India Inning 1"
  const name = inningStr.replace(/\s+Inning.*$/i, "").trim();
  for (const [code, val] of Object.entries(TEAM_MAP)) {
    if (val.apiName === name) return code.replace(/_[MW]$/, "");
  }
  return name.substring(0, 3).toUpperCase();
}

function calcTarget(match) {
  if (!match.score || match.score.length < 2) return null;
  const firstInnings = match.score[0];
  return firstInnings.r + 1;
}

function calcRRR(match, current) {
  const target = calcTarget(match);
  if (!target) return null;
  const runsNeeded = target - current.runs;
  if (runsNeeded <= 0) return null;

  const type = detectType(match.matchType);
  let totalOvers;
  if (type === "t20") totalOvers = 20;
  else if (type === "odi") totalOvers = 50;
  else return null;

  const oversUsed = parseFloat(current.overs);
  const oversLeft = totalOvers - oversUsed;
  if (oversLeft <= 0) return null;

  return parseFloat((runsNeeded / oversLeft).toFixed(1));
}
