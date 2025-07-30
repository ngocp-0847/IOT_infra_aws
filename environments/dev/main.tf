# =============================================================================
# Dev Environment Configuration
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket = "iot-platform-terraform-state-dev"
    key    = "dev/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "iot_platform" {
  source = "../../"

  # Environment
  environment = "dev"
  aws_region = "ap-southeast-1"
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  
  # Kinesis Configuration
  kinesis_stream_name = "iot-data-stream-dev"
  kinesis_shard_count = 2
  
  # DynamoDB Configuration
  dynamodb_table_name = "iot-processed-data-dev"
  
  # S3 Configuration
  s3_bucket_name = "iot-raw-data-store-dev"
  
  # Lambda Configuration
  lambda_runtime = "python3.11"
  lambda_timeout = 300
  lambda_memory_size = 512
  
  # API Gateway Configuration
  api_gateway_name = "iot-query-api-dev"
  
  # Tags
  tags = {
    Project     = "iot-platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
} 