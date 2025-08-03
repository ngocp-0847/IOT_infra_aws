# =============================================================================
# SQS Queue Module - Free Tier Optimized
# =============================================================================

# SQS Queue cho IoT messages
resource "aws_sqs_queue" "iot_queue" {
  name                       = var.queue_name
  delay_seconds              = 0
  max_message_size           = 262144  # 256KB
  message_retention_seconds  = 345600  # 4 days
  receive_wait_time_seconds  = 20      # Long polling
  visibility_timeout_seconds = 30      # Tối ưu cho Lambda

  # Dead Letter Queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-sqs-queue-${var.environment}"
  })
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600  # 14 days

  tags = merge(var.tags, {
    Name = "${var.project_name}-sqs-dlq-${var.environment}"
  })
}

# CloudWatch Log Group cho SQS
resource "aws_cloudwatch_log_group" "sqs_logs" {
  name              = "/aws/sqs/${var.queue_name}"
  retention_in_days = 7  # Giảm retention để tiết kiệm CloudWatch costs

  tags = merge(var.tags, {
    Name = "${var.project_name}-sqs-logs-${var.environment}"
  })
}

# IAM Policy cho SQS
resource "aws_iam_policy" "sqs_policy" {
  name = "${var.project_name}_sqs_policy_${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.iot_queue.arn,
          aws_sqs_queue.dlq.arn
        ]
      }
    ]
  })
}
