# ─────────────────────────────────────────────────────────────────────────────
# deploy_frontend.ps1
#
# Usage:
#   .\scripts\deploy_frontend.ps1 -Bucket <s3-bucket> -DistId <cloudfront-dist-id>
#
# Required env vars:
#   $env:LAMBDA_URL      — API Gateway invoke URL
#   $env:COGNITO_POOL    — Cognito User Pool ID
#   $env:COGNITO_CLIENT  — Cognito App Client ID
#   $env:AWS_REGION      — AWS region (default: us-east-1)
# ─────────────────────────────────────────────────────────────────────────────
param(
    [Parameter(Mandatory)][string]$Bucket,
    [Parameter(Mandatory)][string]$DistId
)

$LambdaUrl     = $env:LAMBDA_URL
$CognitoPool   = $env:COGNITO_POOL
$CognitoClient = $env:COGNITO_CLIENT
$AwsRegion     = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }

if (-not $LambdaUrl -or -not $CognitoPool -or -not $CognitoClient) {
    Write-Error "Missing required env vars: LAMBDA_URL, COGNITO_POOL, COGNITO_CLIENT"
    exit 1
}

# ── Inject runtime config into js/config.js ───────────────────────────────────
Write-Host "Injecting runtime config into frontend/js/config.js..."

$configPath = "frontend\js\config.js"
$content    = Get-Content -Path $configPath -Raw -Encoding UTF8

$content = $content -replace [regex]::Escape("window.__API_URL__        || """""),  "'$LambdaUrl'"
$content = $content -replace [regex]::Escape("window.__COGNITO_POOL__   || """""),  "'$CognitoPool'"
$content = $content -replace [regex]::Escape("window.__COGNITO_CLIENT__ || """""),  "'$CognitoClient'"
$content = $content -replace [regex]::Escape('window.__AWS_REGION__     || "us-east-1"'), "'$AwsRegion'"

Write-Host ""
Write-Host "--- Config values injected ---"
Write-Host "  LAMBDA_URL:     $LambdaUrl"
Write-Host "  COGNITO_POOL:   $CognitoPool"
Write-Host "  COGNITO_CLIENT: $CognitoClient"
Write-Host "  AWS_REGION:     $AwsRegion"
Write-Host "------------------------------"
Write-Host ""

# Sanity-check that all placeholders were replaced
if ($content -match "window\.__API_URL__") {
    Write-Error "Replacement failed — __API_URL__ placeholder still present. Check quote characters in config.js."
    exit 1
}

$tmpConfig = "$env:TEMP\config_built.js"
[System.IO.File]::WriteAllText($tmpConfig, $content, [System.Text.Encoding]::UTF8)

# ── Upload all frontend assets to S3 ─────────────────────────────────────────
Write-Host "Uploading frontend assets to s3://$Bucket ..."

# index.html — no-cache so browsers always fetch the latest entry point
aws s3 cp "frontend\index.html" "s3://$Bucket/index.html" `
    --content-type "text/html; charset=utf-8" `
    --cache-control "no-cache, no-store, must-revalidate"

# styles.css
aws s3 cp "frontend\styles.css" "s3://$Bucket/styles.css" `
    --content-type "text/css; charset=utf-8" `
    --cache-control "public, max-age=31536000, immutable"

# js/config.js — built version with injected values, no-cache
aws s3 cp $tmpConfig "s3://$Bucket/js/config.js" `
    --content-type "application/javascript; charset=utf-8" `
    --cache-control "no-cache, no-store, must-revalidate"

# Remaining JS modules — long cache (content is stable between deploys)
$jsFiles = @("api", "auth", "upload", "gallery", "ui", "app")
foreach ($f in $jsFiles) {
    aws s3 cp "frontend\js\$f.js" "s3://$Bucket/js/$f.js" `
        --content-type "application/javascript; charset=utf-8" `
        --cache-control "public, max-age=31536000, immutable"
}

# ── Invalidate CloudFront cache ───────────────────────────────────────────────
Write-Host "Invalidating CloudFront distribution $DistId ..."
aws cloudfront create-invalidation `
    --distribution-id $DistId `
    --paths "/*" `
    --output text

Write-Host ""
Write-Host "Frontend deployed successfully!"
$domain = aws cloudfront get-distribution --id $DistId --query "Distribution.DomainName" --output text
Write-Host "URL: https://$domain"
