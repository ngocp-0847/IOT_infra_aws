variable "table_name" {
  description = "Tên DynamoDB table"
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