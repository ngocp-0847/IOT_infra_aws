# =============================================================================
# Variables cho VPC Module
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones để triển khai"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks cho public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks cho private subnets"
  type        = list(string)
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