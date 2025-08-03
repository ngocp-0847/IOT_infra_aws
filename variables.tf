# =============================================================================
# Variables cho IoT Platform Infrastructure
# =============================================================================

variable "aws_region" {
  description = "AWS region để triển khai infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tên project"
  type        = string
  default     = "iot-platform"
}

variable "environment" {
  description = "Môi trường triển khai (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment phải là dev, staging, hoặc prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones để triển khai"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks cho public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks cho private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "sqs_queue_name" {
  description = "Tên SQS Queue"
  type        = string
  default     = "iot-data-queue"
}

variable "dynamodb_table_name" {
  description = "Tên DynamoDB table cho dữ liệu đã xử lý"
  type        = string
  default     = "iot-processed-data"
}

variable "s3_bucket_name" {
  description = "Tên S3 bucket cho dữ liệu thô"
  type        = string
  default     = "iot-raw-data-store"
}

variable "lambda_runtime" {
  description = "Runtime cho Lambda functions"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Timeout cho Lambda functions (seconds)"
  type        = number
  default     = 300
  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout phải từ 3 đến 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Memory size cho Lambda functions (MB)"
  type        = number
  default     = 512
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size phải từ 128 đến 10240 MB."
  }
}

variable "api_gateway_name" {
  description = "Tên API Gateway"
  type        = string
  default     = "iot-query-api"
}

variable "alert_email" {
  description = "Email để nhận monitoring alerts"
  type        = string
  default     = "bombaytera123@gmail.com"
}

variable "enable_email_alerts" {
  description = "Bật email alerts cho monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags chung cho tất cả resources"
  type        = map(string)
  default = {
    Project     = "iot-platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
} 