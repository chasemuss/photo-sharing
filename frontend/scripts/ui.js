/**
 * ui.js — Shared UI primitives: lightbox, toast notifications, and utilities.
 */

// ── Lightbox ──────────────────────────────────────────────────────────────────
function openLightbox(url, caption) {
  document.getElementById("lb-img").src            = url;
  document.getElementById("lb-caption").textContent = caption;
  document.getElementById("lightbox").classList.add("open");
}

function closeLightbox() {
  document.getElementById("lightbox").classList.remove("open");
}

// Close lightbox on Escape key
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") closeLightbox();
});

// ── Toast ─────────────────────────────────────────────────────────────────────
let _toastTimer;

/**
 * Show a transient notification at the bottom of the screen.
 * @param {string} msg   - Message text
 * @param {string} type  - Optional CSS modifier: "success" | "error" | ""
 */
function toast(msg, type = "") {
  const el = document.getElementById("toast");
  el.textContent = msg;
  el.className   = `show ${type}`.trim();
  clearTimeout(_toastTimer);
  _toastTimer = setTimeout(() => { el.className = ""; }, 3000);
}

// ── Utilities ─────────────────────────────────────────────────────────────────

/**
 * Escape a string for safe insertion into HTML attribute values or text nodes.
 * @param {*} s
 * @returns {string}
 */
function escHtml(s) {
  return String(s || "")
    .replace(/&/g,  "&amp;")
    .replace(/</g,  "&lt;")
    .replace(/>/g,  "&gt;")
    .replace(/"/g,  "&quot;");
}
