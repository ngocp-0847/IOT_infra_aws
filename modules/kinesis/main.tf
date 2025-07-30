# =============================================================================
# Kinesis Data Stream Module
# =============================================================================

resource "aws_kinesis_stream" "iot_stream" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-kinesis-stream-${var.environment}"
  })
}

# CloudWatch Log Group cho Kinesis
resource "aws_cloudwatch_log_group" "kinesis_logs" {
  name              = "/aws/kinesis/${var.stream_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-kinesis-logs-${var.environment}"
  })
} 