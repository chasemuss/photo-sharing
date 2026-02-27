---
tags: [ops, customization, extensions]
---

# 🔧 Customization & Extensions

> [[Home]] > Customization

---

## Configuration Knobs

| What | Where | How |
|---|---|---|
| AWS region | `terraform/variables.tf` | Change `aws_region` default |
| Project name / resource prefix | `terraform/variables.tf` | Change `project_name` default |
| Pre-signed URL expiry | `lambda_env.PRESIGN_EXPIRY` in `lambda.tf` | Seconds (default `3600`) |
| Photo fetch limit | `get_photos.py` | Change default/max `limit` values |
| Token validity | `cognito.tf` | `access_token_validity`, `refresh_token_validity` |
| CloudFront price class | `cloudfront.tf` | `PriceClass_100` → `PriceClass_All` for global edge |
| Log retention | `lambda.tf`, `apigateway.tf` | `retention_in_days` |

---

## Extension Ideas

### Image Resizing
Add a Lambda triggered by S3 `s3:ObjectCreated:*` events on the images bucket. Use Pillow to generate thumbnails and write them back to S3.

### Custom Domain
```hcl
# cloudfront.tf
aliases = ["photos.yourdomain.com"]
viewer_certificate {
  acm_certificate_arn = aws_acm_certificate.main.arn
  ssl_support_method  = "sni-only"
}
```

Also requires `aws_route53_record` pointing to the CloudFront domain.

### Restrict Signup to Allowlist
Add a Cognito **Pre Sign-up Lambda trigger**:
```python
ALLOWED_EMAILS = {"alice@example.com", "bob@example.com"}

def lambda_handler(event, context):
    if event["request"]["userAttributes"]["email"] not in ALLOWED_EMAILS:
        raise Exception("Not authorized")
    return event
```

### Likes / Comments
1. Add a `comments` DynamoDB table (PK: `photo_id`, SK: `comment_id`)
2. Add new Lambda handlers (`add_comment.py`, `get_comments.py`)
3. Add API Gateway routes (`POST /photos/{id}/comments`, `GET /photos/{id}/comments`)
4. Extend IAM policy with `comments` table ARN

### Rust Backend (Future)
The Lambda runtime supports Rust via the `lambda_runtime` crate. To migrate a handler:
1. Create a Rust binary in a `lambda-rust/` workspace
2. Cross-compile to `x86_64-unknown-linux-musl`
3. Package as a Lambda zip with `bootstrap` binary
4. Change `runtime = "provided.al2023"` and `handler = "bootstrap"` in `lambda.tf`

---

## Related Notes

- [[Infrastructure Index|00 Infrastructure Index]]
- [[Lambda/Lambda Index|Lambda Index]]
- [[Architecture/System Overview|System Overview]]
