/**
 * gallery.js — Fetches photos from the API and renders the masonry grid.
 */

// ── Load & render ─────────────────────────────────────────────────────────────
async function loadPhotos() {
  const gallery = document.getElementById("gallery");

  // Show skeleton placeholders while loading
  gallery.innerHTML =
    '<div class="skeleton" style="height:200px;width:100%;margin-bottom:12px"></div>'.repeat(6);

  try {
    const res = await apiFetch("GET", "/photos");
    if (!res.ok) throw new Error("Failed to load photos");
    const { photos } = await res.json();

    document.getElementById("photo-count").textContent =
      photos.length ? `${photos.length} photo${photos.length === 1 ? "" : "s"}` : "";

    if (!photos.length) {
      gallery.innerHTML = `
        <div class="empty" style="columns:unset">
          <div class="empty-glyph">&#x1F4F7;</div>
          <div class="empty-title">No photos yet</div>
          <div class="empty-sub">Be the first to share a moment</div>
        </div>`;
      return;
    }

    gallery.innerHTML = photos.map(photoCard).join("");
  } catch {
    gallery.innerHTML = `
      <div class="empty">
        <div class="empty-title" style="color:var(--red)">Could not load photos</div>
      </div>`;
  }
}

// ── Card template ─────────────────────────────────────────────────────────────
function photoCard(p) {
  const date = new Date(p.uploaded_at).toLocaleDateString("en-US", {
    month: "short",
    day:   "numeric",
    year:  "numeric",
  });

  const deleteBtn = STATE.currentUser
    ? `<button class="delete-btn"
         onclick="event.stopPropagation(); deletePhoto('${p.photo_id}')">Delete</button>`
    : "";

  const caption = p.caption
    ? `<div class="photo-caption">${escHtml(p.caption)}</div>`
    : "";

  return `
    <div class="photo-card"
         onclick="openLightbox('${escHtml(p.image_url)}', '${escHtml(p.caption)}')">
      <img src="${escHtml(p.image_url)}" alt="${escHtml(p.caption)}" loading="lazy" />
      ${deleteBtn}
      <div class="photo-meta">
        ${caption}
        <div class="photo-byline">
          <span class="photo-author">${escHtml(p.nickname)}</span>
          <span class="photo-date">${date}</span>
        </div>
      </div>
    </div>`;
}

// ── Delete ────────────────────────────────────────────────────────────────────
async function deletePhoto(photoId) {
  if (!confirm("Delete this photo?")) return;
  try {
    const res = await apiFetch("DELETE", `/photos/${photoId}`);
    if (!res.ok) throw new Error((await res.json()).error || "Delete failed");
    toast("Photo deleted.", "success");
    loadPhotos();
  } catch (e) {
    toast(e.message, "error");
  }
}
