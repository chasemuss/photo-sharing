---
tags: [architecture, aws, overview]
---

# 🏛️ System Overview

> [[Home]] > Architecture

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                          Users / Browser                             │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ HTTPS
                    ┌───────────▼───────────┐
                    │      CloudFront CDN    │  ← SSL termination,
                    │   (us-east-1 + edge)  │    caching, gzip
                    └─────┬─────────┬───────┘
                          │         │
               ┌──────────▼──┐  ┌───▼────────────────────┐
               │  S3 Frontend│  │     API Gateway (HTTP)  │
               │  (static)   │  │     Python 3.12 Lambda  │
               └─────────────┘  └───────┬────────┬────────┘
                                        │        │
                               ┌────────▼──┐  ┌──▼────────────┐
                               │ DynamoDB  │  │   S3 Images   │
                               │  Photos   │  │  (objects)    │
                               └───────────┘  └───────────────┘
                    ┌──────────────────────┐
                    │  Cognito User Pool   │◄── Browser (direct)
                    │  (Auth + JWT tokens) │
                    └──────────────────────┘
```

---

## AWS Services

| Service | Role | Config |
|---|---|---|
| **CloudFront** | CDN, HTTPS termination, gzip | `PriceClass_100`, redirect HTTP→HTTPS |
| **S3** (frontend) | Static website hosting | Public read, website endpoint |
| **S3** (images) | Photo object store | Public `GetObject` on `photos/*` |
| **API Gateway v2** | HTTP API routing | CORS enabled, `$default` stage |
| **Lambda** (×4) | Serverless Python API | Python 3.12, 128 MB, 10–15s timeout |
| **DynamoDB** | Photo metadata | PAY_PER_REQUEST, GSI for date sort |
| **Cognito** | User registration + JWT auth | Email verified, SRP + password auth |
| **IAM** | Least-privilege Lambda role | S3 + DynamoDB scoped policy |
| **CloudWatch** | Logs for Lambda + API GW | 14-day retention |

---

## Data Flow — Photo Upload

```
1. Browser  POST /upload-url  ──►  Lambda (upload_url.py)
                                     ├── Validates JWT (Cognito)
                                     ├── Creates DynamoDB record
                                     └── Returns pre-signed S3 PUT URL

2. Browser  PUT <presigned>  ──►  S3 (image bytes, never touch Lambda)

3. Browser  GET /photos      ──►  Lambda (get_photos.py)
                                     └── Queries DynamoDB GSI → returns JSON
```

> See [[Auth Flow]] for the JWT validation detail.
> See [[API Reference]] for all endpoint specs.

---

## Data Flow — Auth

```
Register:  Browser → Cognito SignUp → email verification code
Verify:    Browser → Cognito ConfirmSignUp
Sign In:   Browser → Cognito InitiateAuth → AccessToken (1h) + RefreshToken (30d)
API Call:  Browser → API Gateway  (Authorization: Bearer <AccessToken>)
                       └── Lambda → cognito.get_user(AccessToken) → user attrs
```

---

## Related Notes

- [[Infrastructure Index|Infrastructure]] — Terraform resource details
- [[Lambda/Lambda Index|Lambda]] — Handler code walkthrough
- [[Frontend/Frontend Index|Frontend]] — SPA architecture
