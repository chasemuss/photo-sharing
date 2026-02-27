# Lumina — PhotoShare on AWS

A fully AWS-native photo-sharing app. Upload photos, browse the community gallery, and manage your own uploads.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          Users / Browser                             │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ HTTPS
                    ┌───────────▼───────────┐
                    │      CloudFront CDN    │  ← SSL termination,
                    │   (us-east-1 + edge)  │    caching, gzip
                    └─────┬─────────┬───────┘
                          │         │
               ┌──────────▼──┐  ┌───▼────────────────────┐
               │  S3 Bucket  │  │   Lambda Function URL   │
               │  (Frontend) │  │   Python 3.12 Handler   │
               └─────────────┘  └───────┬────────┬────────┘
                                        │        │
                               ┌────────▼──┐  ┌──▼────────────┐
                               │ DynamoDB  │  │   S3 Bucket   │
                               │  Photos   │  │ (Image Store) │
                               └───────────┘  └───────────────┘
                               ┌──────────────────────┐
                               │  Cognito User Pool   │
                               │  (Auth + JWT tokens) │
                               └──────────────────────┘
```

### Services Used
| Service        | Purpose                                                 |
|----------------|---------------------------------------------------------|
| **S3** (×2)    | Static frontend hosting + photo object storage          |
| **CloudFront** | CDN with HTTPS for the frontend                         |
| **Lambda**     | Serverless Python API (Function URL, no API Gateway)    |
| **DynamoDB**   | Photo metadata (photo_id, caption, uploader, timestamp) |
| **Cognito**    | User registration, email verification, JWT auth         |
| **IAM**        | Least-privilege role for Lambda                         |

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform ≥ 1.5
- Python 3.12 (for Lambda, installed by AWS)
- `bash`

---

## Deploy

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Apply infrastructure

```bash
terraform apply
# Review the plan, type "yes"
```

Terraform will output:
- `cloudfront_url` — your website URL
- `lambda_function_url` — the API endpoint
- `cognito_user_pool_id` + `cognito_client_id`
- `deploy_command` — the exact command to deploy the frontend

### 3. Deploy the frontend

Copy the `deploy_command` output and run it from the **project root** (not the terraform/ directory). It looks like:

```bash
LAMBDA_URL="https://xxxx.lambda-url.us-east-1.on.aws/" \
COGNITO_POOL="us-east-1_XXXXXXXX" \
COGNITO_CLIENT="xxxxxxxxxxxxxxxxxxxxxxxxxx" \
AWS_REGION="us-east-1" \
bash scripts/deploy_frontend.sh photoshare-frontend-XXXX EXXXXXXXXXXXXXXX
```

### 4. Visit your site

Open the `cloudfront_url` from the Terraform output. CloudFront may take a minute to propagate.

---

## Usage

1. **Browse** — All uploaded photos are visible to anyone without logging in.
2. **Register** — Click **Sign In → Register**. Enter your name, email, and password. Check your email for a 6-digit verification code.
3. **Upload** — Once signed in, click **+ Upload**, choose an image, add an optional caption, and submit. The file uploads directly to S3 via a pre-signed URL (your API never touches the bytes).
4. **Delete** — Hover any of your own photos and click **Delete**.

---

## API Reference

All endpoints are served by the Lambda Function URL.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/photos` | No | List all photos (newest first) |
| `POST` | `/upload-url` | ✅ Bearer JWT | Get pre-signed S3 PUT URL + create DDB record |
| `DELETE` | `/photos/{id}` | ✅ Bearer JWT | Delete photo (owner only) |
| `GET` | `/health` | No | Health check |

### Upload flow

```
Browser           Lambda              S3
  │  POST /upload-url  │               │
  ├───────────────────►│               │
  │  {upload_url,      │               │
  │   photo_id}        │               │
  │◄───────────────────┤               │
  │                    │               │
  │  PUT <presigned>   image bytes     │
  ├────────────────────────────────────►
  │                    200 OK          │
  │◄───────────────────────────────────┤
```

---

## Project Layout

```
photoshare/
├── terraform/
│   ├── main.tf         # All AWS resources
│   ├── variables.tf    # Region, project name
│   └── outputs.tf      # URLs, IDs, deploy command
├── lambda/
│   └── handler.py      # Python 3.12 API handler
├── frontend/
│   └── index.html      # Single-page app (vanilla JS + Cognito SDK-free auth)
└── scripts/
    └── deploy_frontend.sh   # Builds + uploads frontend to S3, invalidates CF
```

---

## Customization

| What | Where |
|---|---|
| Change AWS region | `terraform/variables.tf` → `aws_region` |
| Change project name/prefix | `terraform/variables.tf` → `project_name` |
| Add image resizing | Add a second Lambda triggered by S3 events |
| Add a custom domain | Add `aws_cloudfront_distribution` aliases + ACM cert in `terraform/main.tf` |
| Add likes/comments | Add a `comments` DynamoDB table + new Lambda routes |
| Restrict signup to allowlist | Add Cognito pre-signup Lambda trigger |

---

## Tear Down

```bash
# First empty the S3 buckets (Terraform can't delete non-empty buckets)
aws s3 rm s3://$(terraform -chdir=terraform output -raw images_bucket) --recursive
aws s3 rm s3://$(terraform -chdir=terraform output -raw frontend_bucket) --recursive

terraform -chdir=terraform destroy
```
