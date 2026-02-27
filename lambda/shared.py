"""
Shared utilities — imported by every Lambda function.
"""
import json
import os
import boto3

# ── AWS clients (reused across warm invocations) ──────────────────────────────
s3      = boto3.client("s3")
ddb     = boto3.resource("dynamodb")
cognito = boto3.client("cognito-idp")

TABLE_NAME  = os.environ["DYNAMODB_TABLE"]
BUCKET_NAME = os.environ["IMAGES_BUCKET"]
REGION      = os.environ.get("AWS_REGION_NAME", "us-east-1")
EXPIRY      = int(os.environ.get("PRESIGN_EXPIRY", "3600"))

table = ddb.Table(TABLE_NAME)

# ── Response helper ───────────────────────────────────────────────────────────
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

# ── Auth helper ───────────────────────────────────────────────────────────────
def get_user_from_event(event: dict) -> dict | None:
    """Extract and validate Cognito JWT from the Authorization header."""
    headers = event.get("headers") or {}
    token = headers.get("authorization", headers.get("Authorization", ""))
    if not token or not token.startswith("Bearer "):
        return None
    try:
        resp  = cognito.get_user(AccessToken=token.split(" ", 1)[1])
        attrs = {a["Name"]: a["Value"] for a in resp["UserAttributes"]}
        return {
            "username": resp["Username"],
            "email":    attrs.get("email", ""),
            "nickname": attrs.get("nickname", resp["Username"]),
        }
    except Exception:
        return None
