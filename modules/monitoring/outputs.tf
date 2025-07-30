output "dashboard_name" {
  description = "Tên CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.iot_dashboard.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN của SNS topic cho alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Tên SNS topic cho alerts"
  value       = aws_sns_topic.alerts.name
} 