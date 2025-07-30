# =============================================================================
# Monitoring Module với CloudWatch
# =============================================================================

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "iot_dashboard" {
  dashboard_name = "${var.project_name}-iot-dashboard-${var.environment}"

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
            ["AWS/Kinesis", "GetRecords.Success", "StreamName", var.kinesis_stream_name],
            [".", "PutRecord.Success", ".", "."],
            [".", "PutRecords.Success", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Kinesis Stream Metrics"
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
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", var.dynamodb_table_name],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "DynamoDB Metrics"
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
            for func_name in var.lambda_function_names : [
              "AWS/Lambda", "Invocations", "FunctionName", func_name
            ]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Lambda Invocations"
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
            for func_name in var.lambda_function_names : [
              "AWS/Lambda", "Duration", "FunctionName", func_name
            ]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Lambda Duration"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "kinesis_errors" {
  alarm_name          = "${var.project_name}-kinesis-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GetRecords.Failed"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Kinesis stream errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    StreamName = var.kinesis_stream_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${var.project_name}-lambda-errors-${each.key}-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda function errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.key
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_errors" {
  alarm_name          = "${var.project_name}-dynamodb-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "DynamoDB system errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = var.dynamodb_table_name
  }
}

# SNS Topic cho alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = var.tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# Data source
data "aws_region" "current" {} 