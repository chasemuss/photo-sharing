---
tags: [lambda, python, shared, utilities]
---

# shared.py

> [[Home]] > [[Lambda/Lambda Index|Lambda]] > shared.py

Imported by every Lambda function. Initializes AWS clients and provides helpers.

---

## AWS Clients

```python
s3      = boto3.client("s3")
ddb     = boto3.resource("dynamodb")
cognito = boto3.client("cognito-idp")
table   = ddb.Table(TABLE_NAME)
```

Clients are module-level — they are **reused across warm Lambda invocations** (connection pooling).

---

## Constants

| Name | Source | Default |
|---|---|---|
| `TABLE_NAME` | `os.environ["DYNAMODB_TABLE"]` | Required |
| `BUCKET_NAME` | `os.environ["IMAGES_BUCKET"]` | Required |
| `REGION` | `os.environ.get("AWS_REGION_NAME")` | `"us-east-1"` |
| `EXPIRY` | `os.environ.get("PRESIGN_EXPIRY")` | `3600` |

---

## `response(status, body)`

```python
def response(status: int, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
        },
        "body": json.dumps(body),
    }
```

Returns the API Gateway Lambda proxy integration format.

---

## `get_user_from_event(event)`

```python
def get_user_from_event(event: dict) -> dict | None:
```

1. Reads `Authorization` header (case-insensitive)
2. Strips `Bearer ` prefix
3. Calls `cognito.get_user(AccessToken=token)`
4. Returns `{"username", "email", "nickname"}` or `None` on any failure

> Cognito validates the token server-side — no local JWT parsing or JWKS fetching needed.

---

## Related Notes

- [[Lambda/Lambda Index|Lambda Index]]
- [[Architecture/Auth Flow|Auth Flow]]
- [[Infrastructure/Lambda Infra|Lambda Terraform env vars]]
