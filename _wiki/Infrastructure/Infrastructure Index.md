---
tags: [terraform, infrastructure, aws, index]
---

# ☁️ Infrastructure Index

> [[Home]] > Infrastructure

All AWS resources are managed by **Terraform ≥ 1.5** in the `terraform/` directory.

---

## Terraform Files

| File | Contents |
|---|---|
| `versions.tf` | Provider requirements (AWS ~5.0, archive ~2.0, random ~3.0) |
| `variables.tf` | `aws_region` (default `us-east-1`), `project_name` (default `photoshare`) |
| `outputs.tf` | All output values including `deploy_command` |
| `s3.tf` | [[Infrastructure/S3\|S3 buckets]] (images + frontend) |
| `cloudfront.tf` | [[Infrastructure/CloudFront\|CloudFront distribution]] |
| `dynamodb.tf` | [[Infrastructure/DynamoDB\|DynamoDB table]] |
| `lambda.tf` | [[Infrastructure/Lambda Infra\|Lambda functions + log groups]] |
| `apigateway.tf` | [[Infrastructure/API Gateway\|API Gateway routes + integrations]] |
| `cognito.tf` | [[Infrastructure/Cognito\|Cognito user pool + client]] |
| `iam.tf` | [[Infrastructure/IAM\|IAM role + policies]] |

---

## Naming Convention

All resources are prefixed with `var.project_name` (`photoshare` by default).
S3 buckets also receive a random 4-byte hex suffix for global uniqueness.

```
photoshare-images-<hex>
photoshare-frontend-<hex>
photoshare-photos          (DynamoDB)
photoshare-users           (Cognito)
photoshare-lambda-role     (IAM)
photoshare-api             (API Gateway)
```

---

## Outputs

| Output | Description |
|---|---|
| `cloudfront_url` | Your website URL (`https://...cloudfront.net`) |
| `api_url` | API Gateway stage invoke URL |
| `images_bucket` | S3 images bucket ID |
| `frontend_bucket` | S3 frontend bucket ID |
| `cognito_user_pool_id` | Cognito pool ID |
| `cognito_client_id` | Cognito app client ID |
| `dynamodb_table` | DynamoDB table name |
| `deploy_command` | PowerShell command to deploy the frontend |
| `cloudwatch_log_groups` | Map of all log group paths |

---

## State & Providers

| Provider | Version |
|---|---|
| `hashicorp/aws` | `~> 5.0` (locked to `5.100.0`) |
| `hashicorp/archive` | `~> 2.0` (locked to `2.7.1`) |
| `hashicorp/random` | `~> 3.0` (locked to `3.8.1`) |

Lock file: `terraform/.terraform.lock.hcl`

---

## Related Notes

- [[Deployment Guide]]
- [[Tear Down]]
