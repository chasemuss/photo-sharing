# ─────────────────────────────────────────────
#  Lambda – Package
# ─────────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda.zip"
}

locals {
  lambda_env = {
    IMAGES_BUCKET  = aws_s3_bucket.images.id
    DYNAMODB_TABLE = aws_dynamodb_table.photos.name
    AWS_REGION_NAME = var.aws_region
    PRESIGN_EXPIRY = "3600"
  }
}

# ─────────────────────────────────────────────
#  Lambda – health
# ─────────────────────────────────────────────
resource "aws_lambda_function" "health" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-health"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "health.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  environment { variables = local.lambda_env }
  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_log_group" "health" {
  name              = "/aws/lambda/${aws_lambda_function.health.function_name}"
  retention_in_days = 14
}

# ─────────────────────────────────────────────
#  Lambda – get_photos
# ─────────────────────────────────────────────
resource "aws_lambda_function" "get_photos" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-get-photos"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "get_photos.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 15
  memory_size      = 128
  environment { variables = local.lambda_env }
  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_log_group" "get_photos" {
  name              = "/aws/lambda/${aws_lambda_function.get_photos.function_name}"
  retention_in_days = 14
}

# ─────────────────────────────────────────────
#  Lambda – upload_url
# ─────────────────────────────────────────────
resource "aws_lambda_function" "upload_url" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-upload-url"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "upload_url.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 15
  memory_size      = 128
  environment { variables = local.lambda_env }
  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_log_group" "upload_url" {
  name              = "/aws/lambda/${aws_lambda_function.upload_url.function_name}"
  retention_in_days = 14
}

# ─────────────────────────────────────────────
#  Lambda – delete_photo
# ─────────────────────────────────────────────
resource "aws_lambda_function" "delete_photo" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-delete-photo"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "delete_photo.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 15
  memory_size      = 128
  environment { variables = local.lambda_env }
  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_log_group" "delete_photo" {
  name              = "/aws/lambda/${aws_lambda_function.delete_photo.function_name}"
  retention_in_days = 14
}
