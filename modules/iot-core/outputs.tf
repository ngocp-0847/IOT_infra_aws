output "iot_endpoint" {
  description = "IoT Core endpoint"
  value       = "https://iot.${data.aws_region.current.name}.amazonaws.com"
}

output "certificate_arn" {
  description = "ARN của IoT certificate"
  value       = aws_iot_certificate.test_cert.arn
}

output "certificate_id" {
  description = "ID của IoT certificate"
  value       = aws_iot_certificate.test_cert.id
}

output "policy_name" {
  description = "Tên IoT policy"
  value       = aws_iot_policy.iot_policy.name
}

# Data source
data "aws_region" "current" {} 