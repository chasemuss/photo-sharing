---
tags: [terraform, cloudfront, cdn]
---

# 🌐 CloudFront

> [[Home]] > [[Infrastructure Index|Infrastructure]] > CloudFront

Distribution: **`photoshare Frontend`**

---

## Configuration

| Setting | Value |
|---|---|
| Origin | S3 website endpoint (`http-only`) |
| Default root object | `index.html` |
| Price class | `PriceClass_100` (US + Europe) |
| Viewer protocol policy | Redirect HTTP → HTTPS |
| Compress | ✅ gzip |
| Default TTL | 3600s (1h) |
| Max TTL | 86400s (24h) |
| SSL | CloudFront default certificate |
| Geo restriction | None |

## SPA Routing

```hcl
custom_error_response {
  error_code         = 404
  response_code      = 200
  response_page_path = "/index.html"
}
```

All unknown paths return `index.html` — required for client-side routing.

## Cache Invalidation

The deploy script always invalidates `/*` after uploading new assets:
```powershell
aws cloudfront create-invalidation --distribution-id $DistId --paths "/*"
```

---

## Related Notes

- [[Infrastructure/S3|S3 Frontend Bucket]]
- [[Deployment Guide]]
