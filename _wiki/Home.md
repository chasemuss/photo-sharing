---
tags: [index, lumina, photoshare]
aliases: [Start Here, Index]
---

# 🌟 Lumina — PhotoShare Wiki

> A fully AWS-native photo-sharing application. Upload, browse, and manage community photos.

---

## 🗺️ Navigation

| Area                                                  | Notes                                            |
| ----------------------------------------------------- | ------------------------------------------------ |
| 🏛️ [[Architecture/System Overview\|System Overview]] | High-level architecture, services, and data flow |
| ☁️ [[Infrastructure Index\|Infrastructure]]           | All Terraform-managed AWS resources              |
| ⚡ [[Lambda/Lambda Index\|Lambda Functions]]           | Python API handlers                              |
| 🖥️ [[Frontend/Frontend Index\|Frontend]]             | Vanilla JS single-page app                       |
| 🚀 [[Deployment Guide]]                               | How to deploy from scratch                       |
| 🔒 [[Architecture/Auth Flow\|Auth Flow]]              | Cognito JWT authentication                       |
| 📐 [[Architecture/API Reference\|API Reference]]      | All endpoints, request/response shapes           |

---

## 🧭 Quick Facts

```
Project name : photoshare (Terraform prefix)
Runtime      : Python 3.12 (Lambda)
Region       : us-east-1 (default, configurable)
Auth         : AWS Cognito — JWT Bearer tokens
Database     : DynamoDB (PAY_PER_REQUEST)
Storage      : S3 (images + frontend)
CDN          : CloudFront
IaC          : Terraform ≥ 1.5
```

---

## 🔗 Key Relationships

```
CloudFront ──► S3 (frontend)
Browser    ──► API Gateway ──► Lambda ──► DynamoDB
                                    └───► S3 (images)
Browser    ──► Cognito (direct auth)
Browser    ──► S3 (direct PUT via pre-signed URL)
```

---

## 📦 Repository Layout

```
photoshare/
├── terraform/       # All AWS infrastructure as code
├── lambda/          # Python 3.12 Lambda handlers
├── frontend/        # Single-page app (HTML + vanilla JS)
└── scripts/         # Deployment scripts (PowerShell)
```

---

*See [[Tear Down]] to destroy all resources.*
