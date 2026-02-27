---
tags: [terraform, dynamodb, database]
---

# 🗄️ DynamoDB

> [[Home]] > [[Infrastructure Index|Infrastructure]] > DynamoDB

Table: **`photoshare-photos`**

---

## Table Schema

| Attribute | Type | Role |
|---|---|---|
| `photo_id` | String | **Primary hash key** (UUID) |
| `gsi_pk` | String | GSI hash key — always `"PHOTO"` |
| `uploaded_at` | String | GSI range key — ISO 8601 UTC timestamp |

### Full Item Shape

```json
{
  "photo_id":          "550e8400-e29b-41d4-a716-446655440000",
  "gsi_pk":            "PHOTO",
  "uploaded_at":       "2024-06-01T14:23:00.123456+00:00",
  "uploader":          "cognito-username",
  "nickname":          "display name",
  "caption":           "optional caption text",
  "original_filename": "my-photo.jpg",
  "object_key":        "photos/550e8400-e29b-41d4-a716-446655440000.jpg",
  "image_url":         "https://photoshare-images-xxx.s3.us-east-1.amazonaws.com/photos/uuid.jpg"
}
```

---

## Global Secondary Index — `ByUploadDate`

| Attribute | Value |
|---|---|
| Hash key | `gsi_pk` |
| Range key | `uploaded_at` |
| Projection | `ALL` |

Used by `get_photos.py` to return all photos newest-first:

```python
table.query(
    IndexName="ByUploadDate",
    KeyConditionExpression="gsi_pk = :pk",
    ExpressionAttributeValues={":pk": "PHOTO"},
    ScanIndexForward=False,   # newest first
    Limit=limit,
)
```

> The `gsi_pk = "PHOTO"` pattern is a **single-partition fan-out** — simple but limited to ~10 GB per partition. For very large datasets consider a time-bucketed approach.

---

## Billing

`PAY_PER_REQUEST` — no capacity planning needed, scales automatically.

---

## Lambda IAM Permissions

```
dynamodb:PutItem, GetItem, Query, Scan, DeleteItem, UpdateItem
Resource: arn:aws:dynamodb:...:table/photoshare-photos
          arn:aws:dynamodb:...:table/photoshare-photos/index/*
```

---

## Related Notes

- [[Lambda/get_photos|get_photos.py]]
- [[Lambda/upload_url|upload_url.py]]
- [[Lambda/delete_photo|delete_photo.py]]
- [[Infrastructure/IAM|IAM Policy]]
