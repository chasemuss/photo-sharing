---
tags: [ops, teardown, cleanup]
---

# 🗑️ Tear Down

> [[Home]] > Tear Down

> ⚠️ This permanently destroys all resources and data. There is no undo.

---

## Step 1 — Empty S3 Buckets

Terraform cannot delete non-empty buckets. Empty them first:

```bash
aws s3 rm s3://$(terraform -chdir=terraform output -raw images_bucket) --recursive
aws s3 rm s3://$(terraform -chdir=terraform output -raw frontend_bucket) --recursive
```

---

## Step 2 — Destroy Infrastructure

```bash
terraform -chdir=terraform destroy
```

Review the plan (all ~25 resources), type `yes`.

---

## What Gets Deleted

- All S3 objects + buckets
- CloudFront distribution
- API Gateway + all routes
- All Lambda functions + log groups
- DynamoDB table + all items
- Cognito user pool + all user accounts
- IAM role + policies

> CloudWatch Log Groups created by Lambda are managed by Terraform and **will** be deleted.

---

## Partial Cleanup

To delete only specific resources:
```bash
terraform destroy -target=aws_lambda_function.upload_url
```

---

## Related Notes

- [[Deployment Guide]]
- [[Infrastructure Index|00 Infrastructure Index]]
