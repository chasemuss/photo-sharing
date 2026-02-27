# ─────────────────────────────────────────────
#  DynamoDB – Photo Metadata
# ─────────────────────────────────────────────
resource "aws_dynamodb_table" "photos" {
  name         = "${var.project_name}-photos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "photo_id"

  attribute {
    name = "photo_id"
    type = "S"
  }

  attribute {
    name = "uploaded_at"
    type = "S"
  }

  attribute {
    name = "gsi_pk"
    type = "S"
  }

  global_secondary_index {
    name            = "ByUploadDate"
    hash_key        = "gsi_pk"
    range_key       = "uploaded_at"
    projection_type = "ALL"
  }

  tags = { Project = var.project_name }
}
