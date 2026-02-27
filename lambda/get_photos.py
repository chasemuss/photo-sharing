"""
GET /photos — return all photos newest-first.
"""
from shared import table, response


def lambda_handler(event, _context):
    qs    = event.get("queryStringParameters") or {}
    limit = min(int(qs.get("limit", 50)), 100)

    result = table.query(
        IndexName="ByUploadDate",
        KeyConditionExpression="gsi_pk = :pk",
        ExpressionAttributeValues={":pk": "PHOTO"},
        ScanIndexForward=False,
        Limit=limit,
    )

    photos = [
        {
            "photo_id":    item["photo_id"],
            "image_url":   item["image_url"],
            "caption":     item.get("caption", ""),
            "nickname":    item.get("nickname", item.get("uploader", "Unknown")),
            "uploaded_at": item["uploaded_at"],
        }
        for item in result.get("Items", [])
    ]

    return response(200, {"photos": photos, "count": len(photos)})
