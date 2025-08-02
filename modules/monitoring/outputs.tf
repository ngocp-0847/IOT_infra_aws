# =============================================================================
# Monitoring Module Outputs
# =============================================================================

output "sns_topic_arn" {
  description = "ARN của SNS topic cho monitoring alerts"
  value       = aws_sns_topic.monitoring.arn
}

output "dashboard_name" {
  description = "Tên CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
