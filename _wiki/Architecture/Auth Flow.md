---
tags: [auth, cognito, jwt, security]
---

# 🔒 Auth Flow

> [[Home]] > [[Architecture/System Overview|Architecture]] > Auth Flow

---

## Cognito User Pool Config

| Setting | Value |
|--------------------------|-------------------------------------------------------------|
| Pool name                | `photoshare-users`                                          |
| Auto-verified attributes | `email`                                                     |
| Auth flows               | `USER_PASSWORD_AUTH`, `USER_SRP_AUTH`, `REFRESH_TOKEN_AUTH` |
| Access token validity    | **1 hour**                                                  |
| ID token validity        | **1 hour**                                                  |
| Refresh token validity   | **30 days**                                                 |
| Minimum password length  | 8                                                           |
| Required: lowercase      | Yes                                                         |
| Required: uppercase      | Yes                                                         |
| Required: numbers        | Yes                                                         |
| Required: symbols        | No                                                          |

---

## Registration Flow

```
1. Browser calls Cognito directly (no Lambda intermediary):
   POST https://cognito-idp.<region>.amazonaws.com/
   X-Amz-Target: AWSCognitoIdentityProviderService.SignUp
   {
     ClientId, Username (email), Password,
     UserAttributes: [email, nickname]
   }

2. Cognito sends a 6-digit code to the user's email.

3. Browser calls ConfirmSignUp with the code.

4. User proceeds to sign in.
```

> ⚠️ The frontend talks **directly** to Cognito's REST API — no Amplify SDK required.

---

## Sign-In Flow

```
POST AWSCognitoIdentityProviderService.InitiateAuth
{
  AuthFlow: "USER_PASSWORD_AUTH",
  ClientId: <from CONFIG>,
  AuthParameters: { USERNAME: email, PASSWORD: pass }
}

Response → AuthenticationResult.AccessToken  (stored in localStorage)
```

---

## Token Storage

Tokens are stored in `localStorage` under the key `lumina_access`.

```js
// auth.js — persist
localStorage.setItem("lumina_access", STATE.accessToken);

// config.js — restore on load
STATE.accessToken = localStorage.getItem("lumina_access") || null;
```

> ⚠️ **Security note:** `localStorage` is vulnerable to XSS. For higher-security deployments consider `httpOnly` cookies or short-lived tokens only.

---

## Lambda JWT Validation

Lambda functions call `shared.get_user_from_event()`:

```python
# shared.py
def get_user_from_event(event: dict) -> dict | None:
    token = headers.get("authorization", "")
    if not token.startswith("Bearer "): return None
    resp = cognito.get_user(AccessToken=token.split(" ", 1)[1])
    attrs = {a["Name"]: a["Value"] for a in resp["UserAttributes"]}
    return {
        "username": resp["Username"],
        "email":    attrs.get("email", ""),
        "nickname": attrs.get("nickname", resp["Username"]),
    }
```

- Calls Cognito's `GetUser` API — **no local JWT verification** — Cognito validates the token server-side.
- Returns `None` on any failure → Lambda returns `401`.

---

## Protected Endpoints

| Endpoint              | Auth required           |
|-----------------------|-------------------------|
| `GET /health`         | No                      |
| `GET /photos`         | No                      |
| `POST /upload-url`    | Bearer JWT              |
| `DELETE /photos/{id}` | Bearer JWT (owner only) |

---

## Related Notes

- [[Architecture/System Overview|System Overview]]
- [[Infrastructure/Cognito|Cognito Terraform]]
- [[Lambda/shared|shared.py utilities]]
