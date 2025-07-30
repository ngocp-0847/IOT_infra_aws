output "stream_name" {
  description = "Tên Kinesis stream"
  value       = aws_kinesis_stream.iot_stream.name
}

output "stream_arn" {
  description = "ARN của Kinesis stream"
  value       = aws_kinesis_stream.iot_stream.arn
}

output "stream_id" {
  description = "ID của Kinesis stream"
  value       = aws_kinesis_stream.iot_stream.id
} 