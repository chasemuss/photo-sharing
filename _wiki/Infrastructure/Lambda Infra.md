---
tags: [terraform, lambda, serverless]
---

# ⚡ Lambda Infrastructure

> [[Home]] > [[Infrastructure Index|Infrastructure]] > Lambda Infra

---

## Packaging

All Lambda functions share **one zip archive** built from the `lambda/` directory:

```hcl
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda.zip"
}
```

> `terraform/lambda.zip` is gitignored — rebuilt on every `terraform apply`.

---

## Functions

| Resource | Handler | Timeout | Memory |
|---|---|---|---|
| `photoshare-health` | `health.lambda_handler` | 10s | 128 MB |
| `photoshare-get-photos` | `get_photos.lambda_handler` | 15s | 128 MB |
| `photoshare-upload-url` | `upload_url.lambda_handler` | 15s | 128 MB |
| `photoshare-delete-photo` | `delete_photo.lambda_handler` | 15s | 128 MB |

Runtime: **Python 3.12**

---

## Environment Variables

Shared across all functions via a local:

```hcl
locals {
  lambda_env = {
    IMAGES_BUCKET   = aws_s3_bucket.images.id
    DYNAMODB_TABLE  = aws_dynamodb_table.photos.name
    AWS_REGION_NAME = var.aws_region
    PRESIGN_EXPIRY  = "3600"
  }
}
```

| Variable | Used in |
|---|---|
| `IMAGES_BUCKET` | `shared.py`, `upload_url.py`, `delete_photo.py` |
| `DYNAMODB_TABLE` | `shared.py` |
| `AWS_REGION_NAME` | `shared.py` (for image URL construction) |
| `PRESIGN_EXPIRY` | `shared.py` (pre-signed URL TTL in seconds) |

---

## CloudWatch Log Groups

Each function has a dedicated log group with **14-day retention**:

```
/aws/lambda/photoshare-health
/aws/lambda/photoshare-get-photos
/aws/lambda/photoshare-upload-url
/aws/lambda/photoshare-delete-photo
```

---

## Related Notes

- [[Lambda/Lambda Index|Lambda Handlers]]
- [[Infrastructure/IAM|IAM Role]]
- [[Infrastructure/API Gateway|API Gateway]]
