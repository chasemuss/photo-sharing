"""
DELETE /photos/{photo_id} — delete a photo (owner only).
Requires a valid Cognito JWT in the Authorization header.
"""
from botocore.exceptions import ClientError

from shared import s3, table, response, get_user_from_event, BUCKET_NAME


def lambda_handler(event, _context):
    user = get_user_from_event(event)
    if not user:
        return response(401, {"error": "Authentication required"})

    photo_id = (event.get("pathParameters") or {}).get("photo_id", "").strip()
    if not photo_id:
        return response(400, {"error": "Missing photo_id"})

    try:
        result = table.get_item(Key={"photo_id": photo_id})
        item   = result.get("Item")
    except ClientError as e:
        return response(500, {"error": str(e)})

    if not item:
        return response(404, {"error": "Photo not found"})

    if item["uploader"] != user["username"]:
        return response(403, {"error": "You can only delete your own photos"})

    try:
        s3.delete_object(Bucket=BUCKET_NAME, Key=item["object_key"])
    except ClientError:
        pass  # S3 object may already be gone; proceed to clean up DynamoDB

    table.delete_item(Key={"photo_id": photo_id})

    return response(200, {"deleted": photo_id})
