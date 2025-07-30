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

variable "kinesis_stream_arn" {
  description = "ARN của Kinesis stream"
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