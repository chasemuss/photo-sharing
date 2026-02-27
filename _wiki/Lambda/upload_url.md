---
tags: [lambda, python, upload, s3, presigned]
---

# upload_url.py

> [[Home]] > [[Lambda/Lambda Index|Lambda]] > upload_url.py

**Route:** `POST /upload-url`  
**Auth:** ✅ Cognito JWT required

---

## Flow

```
1. Validate JWT → get user (username, nickname)
2. Parse request body (filename, content_type, caption)
3. Validate content_type starts with "image/"
4. Generate UUID photo_id + S3 object key: photos/<uuid>.<ext>
5. Generate pre-signed S3 PUT URL (1h TTL)
6. Write full metadata to DynamoDB
7. Return { upload_url, photo_id, object_key }
```

---

## DynamoDB Record Written

```python
table.put_item(Item={
    "photo_id":          photo_id,
    "gsi_pk":            "PHOTO",
    "object_key":        object_key,
    "uploaded_at":       now,           # UTC ISO 8601
    "uploader":          user["username"],
    "nickname":          user["nickname"],
    "caption":           caption,
    "original_filename": filename,
    "image_url":         f"https://{BUCKET_NAME}.s3.{REGION}.amazonaws.com/{object_key}",
})
```

> The DynamoDB record is written **before** the S3 upload completes. If the browser upload fails, orphaned records can accumulate. A cleanup job or S3 event trigger could prune these.

---

## Pre-signed URL

```python
s3.generate_presigned_url(
    "put_object",
    Params={
        "Bucket":      BUCKET_NAME,
        "Key":         object_key,
        "ContentType": content_type,
    },
    ExpiresIn=EXPIRY,   # default 3600
)
```

The browser uses this URL directly — image bytes **never pass through Lambda**.

---

## Related Notes

- [[Lambda/shared|shared.py]]
- [[Infrastructure/S3|S3 Images Bucket]]
- [[Infrastructure/DynamoDB|DynamoDB]]
- [[Architecture/API Reference|API Reference]]
