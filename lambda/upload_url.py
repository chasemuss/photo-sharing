"""
POST /upload-url — generate a pre-signed S3 PUT URL and record metadata.
Requires a valid Cognito JWT in the Authorization header.
"""
import json
import uuid
from datetime import datetime, timezone

from shared import s3, table, response, get_user_from_event, BUCKET_NAME, REGION, EXPIRY


def lambda_handler(event, _context):
    user = get_user_from_event(event)
    if not user:
        return response(401, {"error": "Authentication required"})

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return response(400, {"error": "Invalid JSON body"})

    filename     = body.get("filename", "photo.jpg")
    content_type = body.get("content_type", "image/jpeg")
    caption      = body.get("caption", "").strip()

    if not content_type.startswith("image/"):
        return response(400, {"error": "Only image uploads are allowed"})

    photo_id   = str(uuid.uuid4())
    ext        = filename.rsplit(".", 1)[-1].lower() if "." in filename else "jpg"
    object_key = f"photos/{photo_id}.{ext}"

    upload_url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket":      BUCKET_NAME,
            "Key":         object_key,
            "ContentType": content_type,
        },
        ExpiresIn=EXPIRY,
    )

    now = datetime.now(timezone.utc).isoformat()
    table.put_item(Item={
        "photo_id":          photo_id,
        "gsi_pk":            "PHOTO",
        "object_key":        object_key,
        "uploaded_at":       now,
        "uploader":          user["username"],
        "nickname":          user["nickname"],
        "caption":           caption,
        "original_filename": filename,
        "image_url":         f"https://{BUCKET_NAME}.s3.{REGION}.amazonaws.com/{object_key}",
    })

    return response(200, {
        "upload_url": upload_url,
        "photo_id":   photo_id,
        "object_key": object_key,
    })
