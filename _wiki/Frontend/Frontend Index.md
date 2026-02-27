---
tags: [frontend, javascript, spa, index]
---

# 🖥️ Frontend Index

> [[Home]] > Frontend

A vanilla JavaScript single-page app served from S3 + CloudFront. No frameworks, no build step.

---

## File Structure

```
frontend/
├── index.html        # HTML shell + modals
├── styles.css        # All CSS (dark luxury theme)
└── js/
    ├── config.js     # Runtime config + shared state
    ├── api.js        # fetch() wrapper
    ├── auth.js       # Cognito auth + modal UI
    ├── upload.js     # Upload modal + direct-to-S3 XHR
    ├── gallery.js    # Photo grid rendering + delete
    ├── ui.js         # Lightbox, toast, escHtml
    └── app.js        # Entry point
```

---

## Script Load Order

Scripts are loaded in dependency order via `<script src="...">` tags:

```
config.js   → defines CONFIG and STATE (no deps)
api.js      → uses CONFIG, STATE
auth.js     → uses CONFIG, STATE, apiFetch, toast, loadPhotos
upload.js   → uses STATE, apiFetch, toast, loadPhotos
gallery.js  → uses STATE, apiFetch, escHtml, toast
ui.js       → pure DOM utilities
app.js      → calls initUser(), updateHeader(), loadPhotos()
```

---

## Runtime Config Injection

`config.js` ships with placeholder strings:

```js
const CONFIG = {
  API_URL:        window.__API_URL__        || "",
  COGNITO_POOL:   window.__COGNITO_POOL__   || "",
  COGNITO_CLIENT: window.__COGNITO_CLIENT__ || "",
  AWS_REGION:     window.__AWS_REGION__     || "us-east-1",
};
```

The deploy script replaces these with real values before uploading to S3.

---

## Shared State

```js
const STATE = {
  accessToken:  localStorage.getItem("lumina_access") || null,
  currentUser:  null,       // populated after initUser()
  pendingEmail: "",         // used during signup verification
  selectedFile: null,       // file chosen in upload modal
};
```

---

## Module Notes

- [[auth.js]] — Registration, sign-in, verify, sign-out
- [[gallery.js]] — Photo grid, delete button
- [[upload.js]] — Upload modal, pre-signed PUT
- [[ui.js]] — Lightbox, toast, HTML escaping

---

## Design System

- **Color scheme:** Dark (`#0a0a08`) with gold accents (`#c8a96e`)
- **Typography:** Cormorant Garamond (serif headings) + DM Mono (body)
- **Grid:** CSS `columns` masonry layout
- **Animations:** `fadeUp` modal entry, `shimmer` skeleton loading

---

## Related Notes

- [[Infrastructure/S3|S3 Frontend Bucket]]
- [[Infrastructure/CloudFront|CloudFront]]
- [[Deployment Guide]]
