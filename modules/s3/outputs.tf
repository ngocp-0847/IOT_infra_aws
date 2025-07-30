# =============================================================================
# Outputs cho S3 Module
# =============================================================================

output "bucket_name" {
  description = "Tên S3 bucket"
  value       = aws_s3_bucket.raw_data.bucket
}

output "bucket_arn" {
  description = "ARN của S3 bucket"
  value       = aws_s3_bucket.raw_data.arn
}

output "bucket_id" {
  description = "ID của S3 bucket"
  value       = aws_s3_bucket.raw_data.id
} 