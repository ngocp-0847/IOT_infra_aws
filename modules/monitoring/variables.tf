variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Tên Kinesis stream"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Tên DynamoDB table"
  type        = string
}

variable "lambda_function_names" {
  description = "Danh sách tên Lambda functions"
  type        = list(string)
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
} 