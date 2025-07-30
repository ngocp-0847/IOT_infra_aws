output "table_name" {
  description = "Tên DynamoDB table"
  value       = aws_dynamodb_table.processed_data.name
}

output "table_arn" {
  description = "ARN của DynamoDB table"
  value       = aws_dynamodb_table.processed_data.arn
}

output "table_id" {
  description = "ID của DynamoDB table"
  value       = aws_dynamodb_table.processed_data.id
} 