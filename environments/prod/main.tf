# =============================================================================
# Production Environment Configuration
# =============================================================================

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "iot-platform-terraform-state-prod"
    key    = "prod/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "iot_platform" {
  source = "../../"

  # Environment
  environment = "prod"
  aws_region  = "ap-southeast-1"

  # VPC Configuration
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]



  # DynamoDB Configuration
  dynamodb_table_name = "iot-processed-data-prod"

  # S3 Configuration
  s3_bucket_name = "iot-raw-data-store-prod"

  # Lambda Configuration
  lambda_runtime     = "python3.11"
  lambda_timeout     = 300
  lambda_memory_size = 1024

  # API Gateway Configuration
  api_gateway_name = "iot-query-api-prod"

  # Tags
  tags = {
    Project     = "iot-platform"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
} 