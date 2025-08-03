variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL của SQS queue"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN của SQS queue"
  type        = string
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
} 