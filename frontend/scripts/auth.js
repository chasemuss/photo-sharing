/**
 * auth.js — Cognito authentication helpers and auth modal UI.
 *
 * Talks directly to the Cognito Identity Provider REST API so we don't need
 * the Amplify/Cognito JS SDK as a dependency.
 */

// ── Cognito low-level helper ──────────────────────────────────────────────────
const COGNITO_ENDPOINT = () =>
  `https://cognito-idp.${CONFIG.AWS_REGION}.amazonaws.com/`;

async function cognitoReq(target, body) {
  const res = await fetch(COGNITO_ENDPOINT(), {
    method: "POST",
    headers: {
      "Content-Type": "application/x-amz-json-1.1",
      "X-Amz-Target": target,
    },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.message || data.__type || "Auth error");
  return data;
}

// ── Session bootstrap ─────────────────────────────────────────────────────────
async function initUser() {
  if (!STATE.accessToken) return;
  try {
    const data = await cognitoReq(
      "AWSCognitoIdentityProviderService.GetUser",
      { AccessToken: STATE.accessToken }
    );
    const attrs = Object.fromEntries(
      data.UserAttributes.map((a) => [a.Name, a.Value])
    );
    STATE.currentUser = {
      username: data.Username,
      email:    attrs.email,
      nickname: attrs.nickname || data.Username,
    };
    updateHeader();
  } catch {
    STATE.accessToken = null;
    localStorage.removeItem("lumina_access");
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
function updateHeader() {
  const userStatus = document.getElementById("user-status");
  const authBtn    = document.getElementById("auth-btn");
  const signoutBtn = document.getElementById("signout-btn");
  const uploadBtn  = document.getElementById("upload-btn");

  if (STATE.currentUser) {
    userStatus.innerHTML = `
      <div class="user-chip">
        <span class="user-dot"></span>${STATE.currentUser.nickname}
      </div>`;
    authBtn.style.display    = "none";
    signoutBtn.style.display = "";
    uploadBtn.style.display  = "";
  } else {
    userStatus.innerHTML     = "";
    authBtn.style.display    = "";
    signoutBtn.style.display = "none";
    uploadBtn.style.display  = "none";
  }
}

// ── Modal open / close ────────────────────────────────────────────────────────
function openAuth()  { document.getElementById("auth-overlay").classList.add("open"); }
function closeAuth() { document.getElementById("auth-overlay").classList.remove("open"); }

function switchTab(tab) {
  document.querySelectorAll(".tab").forEach((t, i) =>
    t.classList.toggle("active", (i === 0 && tab === "signin") || (i === 1 && tab === "signup"))
  );
  document.getElementById("signin-form").style.display = tab === "signin" ? "" : "none";
  document.getElementById("signup-form").style.display = tab === "signup" ? "" : "none";
  document.getElementById("verify-form").style.display = "none";
}

// ── Sign In ───────────────────────────────────────────────────────────────────
async function doSignIn() {
  const email = document.getElementById("si-email").value.trim();
  const pass  = document.getElementById("si-pass").value;
  document.getElementById("si-error").textContent = "";

  try {
    const data = await cognitoReq(
      "AWSCognitoIdentityProviderService.InitiateAuth",
      {
        AuthFlow:       "USER_PASSWORD_AUTH",
        ClientId:       CONFIG.COGNITO_CLIENT,
        AuthParameters: { USERNAME: email, PASSWORD: pass },
      }
    );
    STATE.accessToken = data.AuthenticationResult.AccessToken;
    localStorage.setItem("lumina_access", STATE.accessToken);
    await initUser();
    closeAuth();
    toast("Welcome back!", "success");
    loadPhotos();
  } catch (e) {
    document.getElementById("si-error").textContent = e.message;
  }
}

// ── Sign Up ───────────────────────────────────────────────────────────────────
async function doSignUp() {
  const name  = document.getElementById("su-name").value.trim();
  const email = document.getElementById("su-email").value.trim();
  const pass  = document.getElementById("su-pass").value;
  document.getElementById("su-error").textContent = "";

  try {
    await cognitoReq("AWSCognitoIdentityProviderService.SignUp", {
      ClientId:        CONFIG.COGNITO_CLIENT,
      Username:        email,
      Password:        pass,
      UserAttributes: [
        { Name: "email",    Value: email },
        { Name: "nickname", Value: name || email.split("@")[0] },
      ],
    });
    STATE.pendingEmail = email;
    document.getElementById("signup-form").style.display = "none";
    document.getElementById("verify-form").style.display = "";
  } catch (e) {
    document.getElementById("su-error").textContent = e.message;
  }
}

// ── Email verification ────────────────────────────────────────────────────────
async function doVerify() {
  const code = document.getElementById("verify-code").value.trim();
  document.getElementById("verify-error").textContent = "";

  try {
    await cognitoReq("AWSCognitoIdentityProviderService.ConfirmSignUp", {
      ClientId:         CONFIG.COGNITO_CLIENT,
      Username:         STATE.pendingEmail,
      ConfirmationCode: code,
    });
    // Pre-fill sign-in form and switch back
    document.getElementById("verify-form").style.display  = "none";
    document.getElementById("signin-form").style.display  = "";
    document.getElementById("si-email").value = STATE.pendingEmail;
    document.querySelectorAll(".tab")[0].click();
    toast("Account verified! Please sign in.", "success");
  } catch (e) {
    document.getElementById("verify-error").textContent = e.message;
  }
}

// ── Sign Out ──────────────────────────────────────────────────────────────────
function signOut() {
  STATE.accessToken = null;
  STATE.currentUser = null;
  localStorage.removeItem("lumina_access");
  updateHeader();
  toast("Signed out.");
  loadPhotos();
}
