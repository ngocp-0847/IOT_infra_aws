output "stream_processor_function_name" {
  description = "Tên Lambda function cho stream processing"
  value       = aws_lambda_function.stream_processor.function_name
}

output "stream_processor_function_arn" {
  description = "ARN của Lambda function cho stream processing"
  value       = aws_lambda_function.stream_processor.arn
}

output "query_function_name" {
  description = "Tên Lambda function cho query handling"
  value       = aws_lambda_function.query_handler.function_name
}

output "query_function_arn" {
  description = "ARN của Lambda function cho query handling"
  value       = aws_lambda_function.query_handler.arn
}

output "lambda_role_arn" {
  description = "ARN của IAM role cho Lambda"
  value       = aws_iam_role.lambda_role.arn
} 