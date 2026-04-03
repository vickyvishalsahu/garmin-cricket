const CRICAPI_URL = "https://api.cricapi.com/v1/currentMatches";

export async function fetchCurrentMatches(apiKey) {
  const res = await fetch(`${CRICAPI_URL}?apikey=${apiKey}&offset=0`);
  if (!res.ok) {
    throw new Error(`CricAPI returned ${res.status}`);
  }
  const json = await res.json();
  if (json.status !== "success") {
    throw new Error(`CricAPI error: ${json.status}`);
  }
  return json.data || [];
}
