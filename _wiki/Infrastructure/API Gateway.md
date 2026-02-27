---
tags: [terraform, apigateway, http-api]
---

# 🔀 API Gateway

> [[Home]] > [[Infrastructure Index|Infrastructure]] > API Gateway

Type: **HTTP API (v2)** — `photoshare-api`

---

## Routes

| Method | Path | Lambda | Auth |
|---|---|---|---|
| `GET` | `/health` | `photoshare-health` | None |
| `GET` | `/photos` | `photoshare-get-photos` | None |
| `POST` | `/upload-url` | `photoshare-upload-url` | JWT (in Lambda) |
| `DELETE` | `/photos/{photo_id}` | `photoshare-delete-photo` | JWT (in Lambda) |

> Auth is validated **inside Lambda** via Cognito `GetUser`, not at the API Gateway level (no JWT Authorizer resource). This keeps setup simple at the cost of one extra Cognito API call per request.

---

## Stage

Single stage `$default` with `auto_deploy = true`.

No manual deployments needed — changes apply automatically.

---

## CORS Configuration

```hcl
cors_configuration {
  allow_origins = ["*"]
  allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
  allow_headers = ["Content-Type", "Authorization"]
  max_age       = 300
}
```

---

## Access Logging

Logs to CloudWatch: `/aws/api_gw/photoshare-api` (14-day retention)

Fields logged: `requestId`, `sourceIp`, `requestTime`, `protocol`, `httpMethod`, `resourcePath`, `routeKey`, `status`, `responseLength`, `integrationErrorMessage`

---

## Lambda Permissions

Each Lambda function has a `aws_lambda_permission` resource granting API Gateway invoke access:
```
Principal:  apigateway.amazonaws.com
Source ARN: <api-execution-arn>/*/*
```

---

## Related Notes

- [[Architecture/API Reference|API Reference]]
- [[Infrastructure/Lambda Infra|Lambda Infra]]
- [[Architecture/Auth Flow|Auth Flow]]
