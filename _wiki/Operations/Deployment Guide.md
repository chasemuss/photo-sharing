---
tags: [ops, deployment, terraform, aws]
---

# 🚀 Deployment Guide

> [[Home]] > Deployment Guide

---

## Prerequisites

| Tool | Minimum version |
|---|---|
| AWS CLI | Any recent — configured with `aws configure` |
| Terraform | ≥ 1.5 |
| PowerShell | Any (Windows / pwsh on macOS/Linux) |

---

## Step 1 — Terraform Init

```bash
cd terraform
terraform init
```

Downloads providers (AWS, archive, random). Lock file at `.terraform.lock.hcl`.

---

## Step 2 — Terraform Apply

```bash
terraform apply
# Review plan → type "yes"
```

### Resources created (~25)

- 2× S3 buckets + policies
- CloudFront distribution
- API Gateway + stage + 4 routes + 4 integrations
- 4× Lambda functions + CloudWatch log groups
- DynamoDB table + GSI
- Cognito user pool + app client
- IAM role + policies
- Lambda invoke permissions

> ⏱️ CloudFront distributions take **5–10 minutes** to deploy globally.

---

## Step 3 — Deploy Frontend

Copy the `deploy_command` Terraform output and run it from the **project root**:

```powershell
$env:LAMBDA_URL="https://<api-id>.execute-api.us-east-1.amazonaws.com/"
$env:COGNITO_POOL="us-east-1_XXXXXXXX"
$env:COGNITO_CLIENT="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$env:AWS_REGION="us-east-1"
.\scripts\deploy_frontend.ps1 -Bucket photoshare-frontend-<hex> -DistId <CF-dist-id>
```

### What `deploy_frontend.ps1` does

1. Reads string replacement placeholders from `frontend/js/config.js`
2. Substitutes real values from env vars into a temp file
3. Uploads all frontend assets to S3 with appropriate cache headers
4. Invalidates `/*` on CloudFront

### Cache Header Strategy

| File | Cache-Control |
|---|---|
| `index.html` | `no-cache` |
| `js/config.js` | `no-cache` |
| `styles.css` | `public, max-age=31536000` (1 year) |
| `js/*.js` (others) | `public, max-age=31536000` (1 year) |

---

## Step 4 — Visit Site

Open the `cloudfront_url` output. Wait up to 1 minute for CloudFront edge propagation.

---

## Re-deploying

### Infrastructure change
```bash
terraform apply
```

### Frontend-only change
Re-run the `deploy_command` — no Terraform needed.

### Lambda code change
```bash
terraform apply   # re-zips and redeploys all functions
```

---

## Related Notes

- [[Tear Down]]
- [[Infrastructure Index|00 Infrastructure Index]]
- [[Infrastructure/CloudFront|CloudFront]]
