# =============================================================================
# Monitoring Module
# =============================================================================

# CloudWatch Alarm cho Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda function errors detected"
  
  alarm_actions = [aws_sns_topic.monitoring.arn]
  
  tags = var.tags
}

# CloudWatch Alarm cho DynamoDB Throttling
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  alarm_name          = "${var.project_name}-dynamodb-throttling-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "DynamoDB throttling detected"
  
  alarm_actions = [aws_sns_topic.monitoring.arn]
  
  tags = var.tags
}

# CloudWatch Alarm cho SQS Errors
resource "aws_cloudwatch_metric_alarm" "sqs_errors" {
  alarm_name          = "${var.project_name}-sqs-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "300"  # 5 phút
  alarm_description   = "SQS message age too high"
  
  alarm_actions = [aws_sns_topic.monitoring.arn]
  
  tags = var.tags
}

# SNS Topic cho monitoring alerts
resource "aws_sns_topic" "monitoring" {
  name = "${var.project_name}-monitoring-${var.environment}"
  
  tags = var.tags
}

# SNS Topic Subscription (email)
resource "aws_sns_topic_subscription" "email" {
  count     = var.enable_email_alerts ? 1 : 0
  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard cho monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.lambda_function_name}"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Performance"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${var.dynamodb_table_name}"],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Usage"
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/IoT", "ConnectCount", "ClientId", "*"],
            [".", "PublishCount", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "IoT Core Activity"
        }
      }
    ]
  })
} 