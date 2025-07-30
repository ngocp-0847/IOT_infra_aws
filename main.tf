# =============================================================================
# Main Terraform Configuration cho IoT Platform
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random resources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# =============================================================================
# VPC Module
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
  tags                 = var.tags
}

# =============================================================================
# S3 Bucket cho Raw Data Storage
# =============================================================================
module "s3_storage" {
  source = "./modules/s3"

  bucket_name = "${var.s3_bucket_name}-${random_string.suffix.result}"
  environment = var.environment
  project_name = var.project_name
  tags = var.tags
}

# =============================================================================
# Kinesis Data Stream
# =============================================================================
module "kinesis" {
  source = "./modules/kinesis"

  stream_name    = var.kinesis_stream_name
  shard_count    = var.kinesis_shard_count
  environment    = var.environment
  project_name   = var.project_name
  tags           = var.tags
}

# =============================================================================
# DynamoDB cho Processed Data
# =============================================================================
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = var.dynamodb_table_name
  environment  = var.environment
  project_name = var.project_name
  tags         = var.tags
}

# =============================================================================
# Lambda Functions
# =============================================================================
module "lambda" {
  source = "./modules/lambda"

  environment      = var.environment
  project_name     = var.project_name
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  kinesis_stream_arn = module.kinesis.stream_arn
  dynamodb_table_name = module.dynamodb.table_name
  s3_bucket_name   = module.s3_storage.bucket_name
  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [module.vpc.lambda_security_group_id]
  }
  tags = var.tags
}

# =============================================================================
# API Gateway
# =============================================================================
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name        = var.api_gateway_name
  environment     = var.environment
  project_name    = var.project_name
  lambda_function_arn = module.lambda.query_function_arn
  lambda_function_name = module.lambda.query_function_name
  tags = var.tags
}

# =============================================================================
# IoT Core
# =============================================================================
module "iot_core" {
  source = "./modules/iot-core"

  environment  = var.environment
  project_name = var.project_name
  kinesis_stream_arn = module.kinesis.stream_arn
  tags = var.tags
}

# =============================================================================
# Monitoring & CloudWatch
# =============================================================================
module "monitoring" {
  source = "./modules/monitoring"

  environment  = var.environment
  project_name = var.project_name
  kinesis_stream_name = module.kinesis.stream_name
  dynamodb_table_name = module.dynamodb.table_name
  lambda_function_names = [
    module.lambda.stream_processor_function_name,
    module.lambda.query_function_name
  ]
  tags = var.tags
} 