"""
GET /health — simple liveness check.
"""
from shared import response


def lambda_handler(event, _context):
    return response(200, {"status": "ok", "service": "photoshare-api"})
