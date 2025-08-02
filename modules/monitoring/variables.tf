# =============================================================================
# Monitoring Module Variables
# =============================================================================

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "environment" {
  description = "Môi trường (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags cho resources"
  type        = map(string)
  default     = {}
}

variable "enable_email_alerts" {
  description = "Bật email alerts"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email để nhận alerts"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Tên Lambda function để monitor"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Tên DynamoDB table để monitor"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Tên Kinesis stream để monitor"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
} 