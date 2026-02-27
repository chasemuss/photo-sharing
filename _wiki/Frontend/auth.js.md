---
tags: [frontend, javascript, auth, cognito]
---

# auth.js

> [[Home]] > [[Frontend/Frontend Index|Frontend]] > auth.js

Handles all Cognito interactions directly from the browser — **no Amplify SDK**.

---

## Cognito Direct API

```js
const COGNITO_ENDPOINT = () =>
  `https://cognito-idp.${CONFIG.AWS_REGION}.amazonaws.com/`;

async function cognitoReq(target, body) { ... }
```

All calls go to the same endpoint, differentiated by `X-Amz-Target` header.

### Targets Used

| Function | Target |
|---|---|
| `initUser()` | `AWSCognitoIdentityProviderService.GetUser` |
| `doSignIn()` | `AWSCognitoIdentityProviderService.InitiateAuth` |
| `doSignUp()` | `AWSCognitoIdentityProviderService.SignUp` |
| `doVerify()` | `AWSCognitoIdentityProviderService.ConfirmSignUp` |

---

## Functions

### `initUser()`
Called on page load. Uses stored `accessToken` to restore the session by calling Cognito `GetUser`. On failure, clears the token.

### `updateHeader()`
Syncs header UI to `STATE.currentUser` — shows/hides Upload, Sign In, Sign Out buttons and user chip.

### `doSignIn()`
`USER_PASSWORD_AUTH` flow → stores `AccessToken` in `localStorage` and `STATE.accessToken`.

### `doSignUp()`
Creates Cognito user with `email` + `nickname` attributes. Transitions modal to verify step.

### `doVerify()`
Confirms signup with the 6-digit email code. Pre-fills sign-in form on success.

### `signOut()`
Clears `STATE.accessToken`, `STATE.currentUser`, removes localStorage item.

---

## Related Notes

- [[Architecture/Auth Flow|Auth Flow]]
- [[Frontend/Frontend Index|Frontend Index]]
- [[Infrastructure/Cognito|Cognito Terraform]]
