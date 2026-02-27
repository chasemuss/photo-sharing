/**
 * api.js — Thin wrapper around fetch for all Lambda API calls.
 * Automatically attaches the Authorization header when the user is signed in.
 */

function apiFetch(method, path, body) {
  const opts = {
    method,
    headers: { "Content-Type": "application/json" },
  };
  if (STATE.accessToken) {
    opts.headers["Authorization"] = `Bearer ${STATE.accessToken}`;
  }
  if (body) {
    opts.body = JSON.stringify(body);
  }
  return fetch(CONFIG.API_URL + path, opts);
}
