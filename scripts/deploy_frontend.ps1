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

# Upload all frontend assets — new files are included automatically
$noCache = @("index.html", "config.js")
Get-ChildItem -Path frontend -Recurse -File | foreach {
    $key  = $_.FullName.Substring((Resolve-Path frontend).Path.Length + 1).Replace("\", "/")
    $src  = if ($_.Name -eq "config.js") { $tmp } else { $_.FullName }
    $ct   = switch ($_.Extension) {
        ".html" { "text/html; charset=utf-8" }
        ".css"  { "text/css; charset=utf-8" }
        ".js"   { "application/javascript" }
        default { "application/octet-stream" }
    }
    $cc = if ($noCache -contains $_.Name) { "no-cache" } else { "public, max-age=31536000" }
    aws s3 cp $src "s3://$Bucket/$key" --content-type $ct --cache-control $cc
}

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id $DistId --paths "/*"

Write-Host "Done."