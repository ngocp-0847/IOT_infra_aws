output "queue_name" {
  description = "Tên SQS queue"
  value       = aws_sqs_queue.iot_queue.name
}

output "queue_arn" {
  description = "ARN của SQS queue"
  value       = aws_sqs_queue.iot_queue.arn
}

output "queue_url" {
  description = "URL của SQS queue"
  value       = aws_sqs_queue.iot_queue.url
}

output "dlq_arn" {
  description = "ARN của Dead Letter Queue"
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_url" {
  description = "URL của Dead Letter Queue"
  value       = aws_sqs_queue.dlq.url
} 