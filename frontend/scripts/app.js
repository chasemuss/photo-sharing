/**
 * app.js — Application entry point.
 *
 * Runs after all other scripts are loaded. Validates config, restores the
 * user session if a stored token exists, and loads the initial photo gallery.
 */

(async () => {
  // Warn in the console if the deploy script hasn't injected real config values.
  if (!CONFIG.API_URL) {
    console.warn(
      "[Lumina] CONFIG.API_URL is empty. " +
      "Run scripts/deploy_frontend.ps1 to inject runtime configuration."
    );
  }

  await initUser();   // Restore session from localStorage (auth.js)
  updateHeader();     // Sync header buttons to auth state (auth.js)
  loadPhotos();       // Fetch and render the gallery (gallery.js)
})();
