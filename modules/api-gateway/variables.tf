variable "api_name" {
  description = "Tên API Gateway"
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

variable "lambda_function_arn" {
  description = "ARN của Lambda function"
  type        = string
}

variable "lambda_function_name" {
  description = "Tên Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
} 