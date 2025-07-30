# =============================================================================
# Variables cho S3 Module
# =============================================================================

variable "bucket_name" {
  description = "Tên S3 bucket"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "tags" {
  description = "Tags chung cho tất cả resources"
  type        = map(string)
  default     = {}
} 