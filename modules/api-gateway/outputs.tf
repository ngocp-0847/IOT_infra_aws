output "api_id" {
  description = "ID của API Gateway"
  value       = aws_apigatewayv2_api.iot_api.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_arn" {
  description = "ARN của API Gateway"
  value       = aws_apigatewayv2_api.iot_api.arn
} 