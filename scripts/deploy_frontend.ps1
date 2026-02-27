param(
    [Parameter(Mandatory)][string]$Bucket,
    [Parameter(Mandatory)][string]$DistId
)

if (-not $env:LAMBDA_URL -or -not $env:COGNITO_POOL -or -not $env:COGNITO_CLIENT) {
    Write-Error "Missing required env vars: LAMBDA_URL, COGNITO_POOL, COGNITO_CLIENT"
    exit 1
}

$region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }

# Inject config into a temp copy of config.js
$config = Get-Content "frontend\js\config.js" -Raw
$config = $config.Replace('window.__API_URL__        || ""', "'$($env:LAMBDA_URL)'")
$config = $config.Replace('window.__COGNITO_POOL__   || ""', "'$($env:COGNITO_POOL)'")
$config = $config.Replace('window.__COGNITO_CLIENT__ || ""', "'$($env:COGNITO_CLIENT)'")
$config = $config.Replace('window.__AWS_REGION__     || "us-east-1"', "'$region'")
$tmp = "$env:TEMP\config_built.js"
[IO.File]::WriteAllText($tmp, $config)

# Upload assets
aws s3 cp frontend\index.html "s3://$Bucket/index.html" --content-type "text/html; charset=utf-8" --cache-control "no-cache"
aws s3 cp frontend\styles.css "s3://$Bucket/styles.css" --content-type "text/css; charset=utf-8" --cache-control "public, max-age=31536000"
aws s3 cp $tmp "s3://$Bucket/js/config.js" --content-type "application/javascript" --cache-control "no-cache"
aws s3 cp frontend\js\api.js     "s3://$Bucket/js/api.js"     --content-type "application/javascript" --cache-control "public, max-age=31536000"
aws s3 cp frontend\js\auth.js    "s3://$Bucket/js/auth.js"    --content-type "application/javascript" --cache-control "public, max-age=31536000"
aws s3 cp frontend\js\upload.js  "s3://$Bucket/js/upload.js"  --content-type "application/javascript" --cache-control "public, max-age=31536000"
aws s3 cp frontend\js\gallery.js "s3://$Bucket/js/gallery.js" --content-type "application/javascript" --cache-control "public, max-age=31536000"
aws s3 cp frontend\js\ui.js      "s3://$Bucket/js/ui.js"      --content-type "application/javascript" --cache-control "public, max-age=31536000"
aws s3 cp frontend\js\app.js     "s3://$Bucket/js/app.js"     --content-type "application/javascript" --cache-control "public, max-age=31536000"

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id $DistId --paths "/*"

Write-Host "Done."