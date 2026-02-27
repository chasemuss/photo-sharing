---
tags: [terraform, iam, security]
---

# 🔐 IAM

> [[Home]] > [[Infrastructure Index|Infrastructure]] > IAM

---

## Lambda Execution Role — `photoshare-lambda-role`

### Trust Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": { "Service": "lambda.amazonaws.com" }
  }]
}
```

### Attached Managed Policy

`AWSLambdaBasicExecutionRole` — allows Lambda to write logs to CloudWatch.

### Inline Policy — `photoshare-lambda-app-policy`

#### S3 — Image Bucket

```json
{
  "Sid": "S3ImageAccess",
  "Effect": "Allow",
  "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
  "Resource": "arn:aws:s3:::photoshare-images-<hex>/*"
}
```

#### DynamoDB — Photos Table

```json
{
  "Sid": "DynamoDBAccess",
  "Effect": "Allow",
  "Action": [
    "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query",
    "dynamodb:Scan",    "dynamodb:DeleteItem", "dynamodb:UpdateItem"
  ],
  "Resource": [
    "arn:aws:dynamodb:...:table/photoshare-photos",
    "arn:aws:dynamodb:...:table/photoshare-photos/index/*"
  ]
}
```

---

## Principle of Least Privilege Notes

- Lambda **cannot** access any other S3 buckets
- Lambda **cannot** call Cognito admin APIs (user deletion, etc.)
- Lambda **cannot** write to the DynamoDB table's metadata or manage streams
- CloudWatch log access is granted only via the AWS-managed basic execution role

---

## Related Notes

- [[Infrastructure/Lambda Infra|Lambda Infra]]
- [[Infrastructure/S3|S3]]
- [[Infrastructure/DynamoDB|DynamoDB]]
