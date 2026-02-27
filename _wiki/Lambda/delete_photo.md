---
tags: [lambda, python, delete, authorization]
---

# delete_photo.py

> [[Home]] > [[Lambda/Lambda Index|Lambda]] > delete_photo.py

**Route:** `DELETE /photos/{photo_id}`  
**Auth:** ✅ Cognito JWT required (owner only)

---

## Flow

```
1. Validate JWT → get user
2. Extract photo_id from pathParameters
3. Fetch DynamoDB item by photo_id
4. Check item.uploader == user.username  → 403 if not owner
5. Delete S3 object (failure silently ignored)
6. Delete DynamoDB record
7. Return { deleted: photo_id }
```

---

## Owner Check

```python
if item["uploader"] != user["username"]:
    return response(403, {"error": "You can only delete your own photos"})
```

The `uploader` field stores the Cognito username (not nickname), which is stable.

---

## S3 Delete Behaviour

```python
try:
    s3.delete_object(Bucket=BUCKET_NAME, Key=item["object_key"])
except ClientError:
    pass  # S3 object may already be gone; proceed to clean up DynamoDB
```

S3 deletion is **best-effort** — the DynamoDB record is always cleaned up regardless.

---

## Error Responses

| Code | Condition |
|---|---|
| `401` | No/invalid JWT |
| `400` | Missing photo_id path param |
| `404` | Photo not in DynamoDB |
| `403` | Requester is not the uploader |
| `500` | DynamoDB read error |

---

## Related Notes

- [[Lambda/shared|shared.py]]
- [[Infrastructure/S3|S3]]
- [[Infrastructure/DynamoDB|DynamoDB]]
- [[Architecture/Auth Flow|Auth Flow]]
