---
tags: [lambda, python, health]
---

# health.py

> [[Home]] > [[Lambda/Lambda Index|Lambda]] > health.py

**Route:** `GET /health`  
**Auth:** None

---

## Code

```python
from shared import response

def lambda_handler(event, _context):
    return response(200, {"status": "ok", "service": "photoshare-api"})
```

The simplest possible handler — used for load balancer health checks or uptime monitoring.

---

## Related Notes

- [[Lambda/shared|shared.py]]
- [[Architecture/API Reference|API Reference]]
