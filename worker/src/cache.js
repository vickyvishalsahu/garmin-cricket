const TTL_LIVE = 120;
const TTL_COMPLETED = 300;
const TTL_NOT_FOUND = 60;

export async function getCache(kv, teamCode) {
  const raw = await kv.get(`score:${teamCode}`, "text");
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export async function setCache(kv, teamCode, data) {
  let ttl;
  if (!data.found) {
    ttl = TTL_NOT_FOUND;
  } else if (data.match.status === "live") {
    ttl = TTL_LIVE;
  } else {
    ttl = TTL_COMPLETED;
  }

  await kv.put(`score:${teamCode}`, JSON.stringify(data), {
    expirationTtl: ttl,
  });
}
