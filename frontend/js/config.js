/**
 * config.js — Runtime configuration and shared application state.
 *
 * The deploy script (scripts/deploy_frontend.ps1) performs string replacement
 * on THIS file to inject real values before uploading to S3.
 * All other JS modules read from CONFIG and STATE; they never write here.
 */

// ── Runtime config (values injected at deploy time) ──────────────────────────
const CONFIG = {
  API_URL:        window.__API_URL__        || "",
  COGNITO_POOL:   window.__COGNITO_POOL__   || "",
  COGNITO_CLIENT: window.__COGNITO_CLIENT__ || "",
  AWS_REGION:     window.__AWS_REGION__     || "us-east-1",
};

// ── Shared mutable state ──────────────────────────────────────────────────────
const STATE = {
  accessToken:  localStorage.getItem("lumina_access") || null,
  currentUser:  null,
  pendingEmail: "",
  selectedFile: null,
};
