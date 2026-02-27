---
tags: [api, endpoints, reference]
---

# 📐 API Reference

> [[Home]] > [[Architecture/System Overview|Architecture]] > API Reference

Base URL is the API Gateway `$default` stage invoke URL (output: `api_url`).

---

## Endpoints

### `GET /health`

**Auth:** None

**Response `200`:**
```json
{ "status": "ok", "service": "photoshare-api" }
```

---

### `GET /photos`

**Auth:** None

**Query params:**

| Param   | Default | Max   | Description                |
|---------|---------|-------|----------------------------|
| `limit` | `50`    | `100` | Number of photos to return |

**Response `200`:**
```json
{
  "photos": [
    {
      "photo_id":    "uuid",
      "image_url":   "https://bucket.s3.region.amazonaws.com/photos/uuid.jpg",
      "caption":     "optional caption",
      "nickname":    "display name",
      "uploaded_at": "2024-01-01T12:00:00+00:00"
    }
  ],
  "count": 1
}
```

Photos are sorted **newest-first** via the `ByUploadDate` DynamoDB GSI.

---

### `POST /upload-url`

**Auth:** ✅ `Authorization: Bearer <AccessToken>`

**Request body:**
```json
{
  "filename":     "photo.jpg",
  "content_type": "image/jpeg",
  "caption":      "optional caption"
}
```

**Validations:**
- `content_type` must start with `image/`

**Response `200`:**
```json
{
  "upload_url": "https://s3.amazonaws.com/...(presigned PUT URL, 1h expiry)",
  "photo_id":   "uuid",
  "object_key": "photos/uuid.jpg"
}
```

**Side effects:**
- Creates a DynamoDB record with full metadata
- Pre-signed URL allows a direct browser → S3 PUT (Lambda never handles bytes)

**Errors:**

| Code  | Reason                                 |
|-------|----------------------------------------|
| `401` | Missing or invalid JWT                 |
| `400` | Invalid JSON or non-image content type |

---

### `DELETE /photos/{photo_id}`

**Auth:** ✅ `Authorization: Bearer <AccessToken>`

**Path param:** `photo_id` — UUID of the photo

**Response `200`:**
```json
{ "deleted": "uuid" }
```

**Business logic:**
- Fetches DynamoDB record
- Checks `item.uploader == user.username` — **owner-only delete**
- Deletes S3 object (failure silently ignored — record cleaned up anyway)
- Deletes DynamoDB record

**Errors:**

| Code  | Reason                 |
|-------|------------------------|
| `401` | Missing or invalid JWT |
| `400` | Missing `photo_id`     |
| `404` | Photo not found        |
| `403` | Not the owner          |
| `500` | DynamoDB error         |

---

## CORS

API Gateway is configured to allow:
- Origins: `*`
- Methods: `GET, POST, DELETE, OPTIONS`
- Headers: `Content-Type, Authorization`
- Max age: 300s

Lambda response headers also echo CORS headers for direct responses.

---

## Related Notes

- [[Lambda/Lambda Index|Lambda Functions]]
- [[Architecture/Auth Flow|Auth Flow]]
- [[Infrastructure/API Gateway|API Gateway Terraform]]
