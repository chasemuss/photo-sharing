---
tags: [terraform, cognito, auth]
---

# 👤 Cognito

> [[Home]] > [[Infrastructure Index|Infrastructure]] > Cognito

---

## User Pool — `photoshare-users`

```hcl
password_policy {
  minimum_length    = 8
  require_lowercase = true
  require_numbers   = true
  require_symbols   = false
  require_uppercase = true
}
auto_verified_attributes = ["email"]
```

---

## App Client — `photoshare-web-client`

| Setting | Value |
|---|---|
| Auth flows | `ALLOW_USER_PASSWORD_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH`, `ALLOW_USER_SRP_AUTH` |
| Access token | 1 hour |
| ID token | 1 hour |
| Refresh token | 30 days |
| Client secret | ❌ (public client — no secret, used from browser) |

---

## Outputs Referenced

```hcl
output "cognito_user_pool_id"  { value = aws_cognito_user_pool.main.id }
output "cognito_client_id"     { value = aws_cognito_user_pool_client.web.id }
```

These are injected into `js/config.js` at deploy time.

---

## Related Notes

- [[Architecture/Auth Flow|Auth Flow]]
- [[Deployment Guide]]
