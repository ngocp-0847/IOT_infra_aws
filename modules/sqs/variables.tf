variable "queue_name" {
  description = "Tên SQS Queue"
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
  description = "Tags chung"
  type        = map(string)
  default     = {}
}

variable "visibility_timeout_seconds" {
  description = "Visibility Timeout của SQS (phải >= Lambda timeout)"
  type        = number
}