variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout"
  type        = number
}

variable "memory_size" {
  description = "Lambda memory size"
  type        = number
}

# Image tag cho container images của Lambda (mặc định dùng "latest" để có thể update qua GitHub Actions mà không cần đổi Terraform)
variable "stream_processor_image_tag" {
  description = "Docker image tag cho Lambda stream processor"
  type        = string
  default     = "latest"
}

variable "query_handler_image_tag" {
  description = "Docker image tag cho Lambda query handler"
  type        = string
  default     = "latest"
}

variable "sqs_queue_arn" {
  description = "ARN của SQS queue"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Tên DynamoDB table"
  type        = string
}

variable "s3_bucket_name" {
  description = "Tên S3 bucket"
  type        = string
}

variable "vpc_config" {
  description = "VPC config cho Lambda"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
} 