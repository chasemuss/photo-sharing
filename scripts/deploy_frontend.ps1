# Usage: .\scripts\deploy_frontend.ps1 -Bucket <bucket> -DistId <cloudfront-dist-id>
# Required env vars: $env:LAMBDA_URL, $env:COGNITO_POOL, $env:COGNITO_CLIENT, $env:AWS_REGION
param(
    [Parameter(Mandatory)][string]$Bucket,
    [Parameter(Mandatory)][string]$DistId
)

$LambdaUrl     = $env:LAMBDA_URL
$CognitoPool   = $env:COGNITO_POOL
$CognitoClient = $env:COGNITO_CLIENT
$AwsRegion     = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }

if (-not $LambdaUrl -or -not $CognitoPool -or -not $CognitoClient) {
    Write-Error "Missing required environment variables: LAMBDA_URL, COGNITO_POOL, COGNITO_CLIENT"
    exit 1
}

Write-Host "Injecting runtime config into index.html..."

$content = Get-Content -Path "frontend\index.html" -Raw -Encoding UTF8

$content = $content -replace [regex]::Escape("window.__API_URL__ || """""),          "'$LambdaUrl'"
$content = $content -replace [regex]::Escape("window.__COGNITO_POOL__ || """""),     "'$CognitoPool'"
$content = $content -replace [regex]::Escape("window.__COGNITO_CLIENT__ || """""),   "'$CognitoClient'"
$content = $content -replace [regex]::Escape('window.__AWS_REGION__ || "us-east-1"'), "'$AwsRegion'"

Write-Host ""
Write-Host "--- Config values injected ---"
Write-Host "  LAMBDA_URL:     $LambdaUrl"
Write-Host "  COGNITO_POOL:   $CognitoPool"
Write-Host "  COGNITO_CLIENT: $CognitoClient"
Write-Host "  AWS_REGION:     $AwsRegion"
Write-Host "------------------------------"
Write-Host ""

if ($content -match "window\.__API_URL__") {
    Write-Error "Replacement failed - API_URL placeholder still present. Check quote characters in the HTML file."
    exit 1
}

$tmpFile = "$env:TEMP\index_built.html"
[System.IO.File]::WriteAllText($tmpFile, $content, [System.Text.Encoding]::UTF8)

Write-Host "Uploading to S3 bucket: $Bucket..."
aws s3 cp $tmpFile "s3://$Bucket/index.html" --content-type "text/html; charset=utf-8" --cache-control "no-cache, no-store, must-revalidate"

Write-Host "Invalidating CloudFront cache: $DistId..."
aws cloudfront create-invalidation --distribution-id $DistId --paths "/*" --output text

Write-Host ""
Write-Host "Frontend deployed!"
$domain = aws cloudfront get-distribution --id $DistId --query "Distribution.DomainName" --output text
Write-Host "URL: https://$domain"
