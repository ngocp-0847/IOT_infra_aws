# =============================================================================
# Kinesis Data Stream Module - Free Tier Optimized
# =============================================================================

resource "aws_kinesis_stream" "iot_stream" {
  name             = var.stream_name
  retention_period = 24
  shard_count      = 1  # Tối thiểu cho Free Tier, thay vì ON_DEMAND

  tags = merge(var.tags, {
    Name = "${var.project_name}-kinesis-stream-${var.environment}"
  })
}

# CloudWatch Log Group cho Kinesis
resource "aws_cloudwatch_log_group" "kinesis_logs" {
  name              = "/aws/kinesis/${var.stream_name}"
  retention_in_days = 7  # Giảm retention để tiết kiệm CloudWatch costs

  tags = merge(var.tags, {
    Name = "${var.project_name}-kinesis-logs-${var.environment}"
  })
} 