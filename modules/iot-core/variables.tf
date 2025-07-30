variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN của Kinesis stream"
  type        = string
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
} 