resource "aws_dynamodb_table" "processed_data" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"  # Tối ưu cho Free Tier
  hash_key       = "device_id"
  range_key      = "timestamp_hour"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp_hour"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-dynamodb-${var.environment}"
  })
} 