# =============================================================================
# Monitoring Module - Free Tier Optimized
# =============================================================================

# CloudWatch Alarms cho Free Tier Usage
resource "aws_cloudwatch_metric_alarm" "free_tier_usage" {
  alarm_name          = "${var.project_name}-free-tier-usage-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeTierUsage"
  namespace           = "AWS/Usage"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # Cảnh báo khi sử dụng 80% Free Tier
  alarm_description   = "Free Tier usage approaching limit"
  
  alarm_actions = [aws_sns_topic.monitoring.arn]
  
  tags = var.tags
}

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

# CloudWatch Alarm cho Kinesis Errors
resource "aws_cloudwatch_metric_alarm" "kinesis_errors" {
  alarm_name          = "${var.project_name}-kinesis-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Average"
  threshold           = "300000"  # 5 phút
  alarm_description   = "Kinesis consumer lag detected"
  
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

# AWS Budgets để track chi phí
resource "aws_budgets_budget" "cost" {
  name              = "${var.project_name}-cost-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = "10"  # $10/tháng cho Free Tier
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00:00"
  time_unit         = "MONTHLY"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.enable_email_alerts ? [var.alert_email] : []
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.enable_email_alerts ? [var.alert_email] : []
  }
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
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Kinesis", "GetRecords.Records", "StreamName", "${var.kinesis_stream_name}"],
            [".", "PutRecord.Records", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Kinesis Data Flow"
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