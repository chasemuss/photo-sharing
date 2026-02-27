---
tags: [lambda, python, api, index]
---

# ⚡ Lambda Functions Index

> [[Home]] > Lambda

All handlers are Python 3.12. They share utilities from `shared.py`.

---

## Function Map

| File | Route | Purpose |
|---|---|---|
| [[Lambda/shared\|shared.py]] | — | Shared boto3 clients, response helper, auth helper |
| [[Lambda/health\|health.py]] | `GET /health` | Liveness check |
| [[Lambda/get_photos\|get_photos.py]] | `GET /photos` | List photos newest-first |
| [[Lambda/upload_url\|upload_url.py]] | `POST /upload-url` | Generate pre-signed S3 PUT URL |
| [[Lambda/delete_photo\|delete_photo.py]] | `DELETE /photos/{id}` | Owner-only photo delete |

---

## Shared Utilities (`shared.py`)

```python
# Clients (reused across warm invocations)
s3      = boto3.client("s3")
ddb     = boto3.resource("dynamodb")
cognito = boto3.client("cognito-idp")

# Constants from environment
TABLE_NAME  = os.environ["DYNAMODB_TABLE"]
BUCKET_NAME = os.environ["IMAGES_BUCKET"]
REGION      = os.environ.get("AWS_REGION_NAME", "us-east-1")
EXPIRY      = int(os.environ.get("PRESIGN_EXPIRY", "3600"))

table = ddb.Table(TABLE_NAME)
```

### `response(status, body)`
Returns a Lambda proxy integration response dict with CORS headers.

### `get_user_from_event(event)`
Extracts and validates a Cognito `Bearer` token. Returns user dict or `None`.

---

## Error Handling Pattern

```python
user = get_user_from_event(event)
if not user:
    return response(401, {"error": "Authentication required"})
```

All handlers return structured JSON errors, never raise unhandled exceptions.

---

## Related Notes

- [[Infrastructure/Lambda Infra|Lambda Terraform]]
- [[Architecture/API Reference|API Reference]]
- [[Architecture/Auth Flow|Auth Flow]]
