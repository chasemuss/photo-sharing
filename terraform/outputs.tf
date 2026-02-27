output "cloudfront_url" {
  description = "CloudFront distribution URL (your website)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "api_url" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "images_bucket" {
  description = "S3 bucket for uploaded images"
  value       = aws_s3_bucket.images.id
}

output "frontend_bucket" {
  description = "S3 bucket for frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "dynamodb_table" {
  description = "DynamoDB table for photo metadata"
  value       = aws_dynamodb_table.photos.name
}

output "deploy_command" {
  description = "Command to build and deploy the frontend (PowerShell)"
  value       = <<-EOT
    # Deploy frontend (run from project root in PowerShell after `terraform apply`):
    $env:LAMBDA_URL="${aws_apigatewayv2_stage.default.invoke_url}"
    $env:COGNITO_POOL="${aws_cognito_user_pool.main.id}"
    $env:COGNITO_CLIENT="${aws_cognito_user_pool_client.web.id}"
    $env:AWS_REGION="${var.aws_region}"
    .\scripts\deploy_frontend.ps1 -Bucket ${aws_s3_bucket.frontend.id} -DistId ${aws_cloudfront_distribution.frontend.id}
  EOT
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for each Lambda function"
  value = {
    health       = "/aws/lambda/${aws_lambda_function.health.function_name}"
    get_photos   = "/aws/lambda/${aws_lambda_function.get_photos.function_name}"
    upload_url   = "/aws/lambda/${aws_lambda_function.upload_url.function_name}"
    delete_photo = "/aws/lambda/${aws_lambda_function.delete_photo.function_name}"
    api_gateway  = "/aws/apigateway/${var.project_name}"
  }
}
