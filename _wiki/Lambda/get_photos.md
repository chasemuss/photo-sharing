---
tags: [lambda, python, photos, dynamodb]
---

# get_photos.py

> [[Home]] > [[Lambda/Lambda Index|Lambda]] > get_photos.py

**Route:** `GET /photos`  
**Auth:** None

---

## Behaviour

1. Reads optional `limit` query param (default 50, max 100)
2. Queries the `ByUploadDate` GSI on [[Infrastructure/DynamoDB|DynamoDB]]
3. Returns photos sorted **newest-first** (`ScanIndexForward=False`)

---

## Response Shape

```json
{
  "photos": [
    {
      "photo_id":    "uuid",
      "image_url":   "https://...",
      "caption":     "",
      "nickname":    "display name",
      "uploaded_at": "ISO 8601"
    }
  ],
  "count": 12
}
```

Note: `nickname` falls back to `uploader` if not set (legacy data guard).

---

## DynamoDB Query

```python
table.query(
    IndexName="ByUploadDate",
    KeyConditionExpression="gsi_pk = :pk",
    ExpressionAttributeValues={":pk": "PHOTO"},
    ScanIndexForward=False,
    Limit=limit,
)
```

The `gsi_pk = "PHOTO"` constant acts as a global bucket for all photos.

> ⚠️ **Scale note:** A single GSI partition key for all items will hot-partition beyond ~10 GB or very high RCU. See [[Architecture/System Overview#Customization]] for time-bucketing alternatives.

---

## Related Notes

- [[Lambda/shared|shared.py]]
- [[Infrastructure/DynamoDB|DynamoDB]]
- [[Architecture/API Reference|API Reference]]
