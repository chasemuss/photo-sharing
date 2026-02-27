/**
 * upload.js — Upload modal UI and direct-to-S3 upload via pre-signed URL.
 *
 * Flow:
 *  1. POST /upload-url  → Lambda creates DynamoDB record, returns a pre-signed PUT URL.
 *  2. PUT <presigned>   → Browser streams the file bytes directly to S3 (Lambda never
 *                         touches the image bytes).
 */

// ── Modal open / close ────────────────────────────────────────────────────────
function openUpload() {
  STATE.selectedFile = null;
  document.getElementById("chosen-filename").textContent    = "";
  document.getElementById("caption-input").value            = "";
  document.getElementById("upload-error").textContent       = "";
  document.getElementById("progress-wrap").style.display    = "none";
  document.getElementById("progress-fill").style.width      = "0%";
  document.getElementById("upload-overlay").classList.add("open");
}

function closeUpload() {
  document.getElementById("upload-overlay").classList.remove("open");
}

// ── File selection ────────────────────────────────────────────────────────────
function fileChosen(input) {
  STATE.selectedFile = input.files[0] || null;
  document.getElementById("chosen-filename").textContent =
    STATE.selectedFile ? STATE.selectedFile.name : "";
}

function handleDrag(e, active) {
  e.preventDefault();
  document.getElementById("drop-zone").classList.toggle("drag", active);
}

function handleDrop(e) {
  e.preventDefault();
  handleDrag(e, false);
  const file = e.dataTransfer.files[0];
  if (file && file.type.startsWith("image/")) {
    STATE.selectedFile = file;
    document.getElementById("chosen-filename").textContent = file.name;
  }
}

// ── Upload ────────────────────────────────────────────────────────────────────
async function doUpload() {
  if (!STATE.selectedFile) {
    document.getElementById("upload-error").textContent = "Please select an image.";
    return;
  }

  const caption   = document.getElementById("caption-input").value.trim();
  const uploadBtn = document.getElementById("do-upload-btn");

  document.getElementById("upload-error").textContent = "";
  uploadBtn.disabled = true;

  try {
    // Step 1 — request a pre-signed PUT URL from our API
    const res = await apiFetch("POST", "/upload-url", {
      filename:     STATE.selectedFile.name,
      content_type: STATE.selectedFile.type,
      caption,
    });
    if (!res.ok) throw new Error((await res.json()).error || "Upload failed");
    const { upload_url } = await res.json();

    // Step 2 — stream the file directly to S3
    document.getElementById("progress-wrap").style.display = "";
    await uploadToS3(upload_url, STATE.selectedFile);

    closeUpload();
    toast("Photo shared!", "success");
    // Small delay to allow S3 eventual consistency before refreshing the gallery
    setTimeout(loadPhotos, 1200);
  } catch (e) {
    document.getElementById("upload-error").textContent = e.message;
  } finally {
    uploadBtn.disabled = false;
  }
}

/**
 * Upload a file to S3 using a pre-signed URL, reporting progress via XHR.
 * @param {string} url   - Pre-signed S3 PUT URL
 * @param {File}   file  - File object to upload
 * @returns {Promise<void>}
 */
function uploadToS3(url, file) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url);
    xhr.setRequestHeader("Content-Type", file.type);

    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) {
        const pct = Math.round((e.loaded / e.total) * 100);
        document.getElementById("progress-fill").style.width    = `${pct}%`;
        document.getElementById("progress-label").textContent   = `Uploading… ${pct}%`;
      }
    };

    xhr.onload  = () => (xhr.status < 300 ? resolve() : reject(new Error("S3 upload failed")));
    xhr.onerror = () => reject(new Error("Network error during upload"));
    xhr.send(file);
  });
}
