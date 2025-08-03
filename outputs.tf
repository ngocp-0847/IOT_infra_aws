# =============================================================================
# Outputs cho IoT Platform Infrastructure
# =============================================================================

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "iot_endpoint" {
  description = "IoT Core endpoint"
  value       = module.iot_core.iot_endpoint
}



output "dynamodb_table_name" {
  description = "Tên DynamoDB table"
  value       = module.dynamodb.table_name
}

output "s3_bucket_name" {
  description = "Tên S3 bucket cho raw data"
  value       = module.s3_storage.bucket_name
}

output "lambda_functions" {
  description = "Thông tin Lambda functions"
  value = {
    stream_processor = {
      name = module.lambda.stream_processor_function_name
      arn  = module.lambda.stream_processor_function_arn
    }
    query_handler = {
      name = module.lambda.query_function_name
      arn  = module.lambda.query_function_arn
    }
  }
}

output "vpc_info" {
  description = "Thông tin VPC"
  value = {
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids
    public_subnet_ids = module.vpc.public_subnet_ids
  }
}

output "monitoring" {
  description = "Thông tin monitoring"
  value = {
    dashboard_name = module.monitoring.dashboard_name
    sns_topic_arn = module.monitoring.sns_topic_arn
  }
}

output "iot_certificate" {
  description = "Thông tin IoT certificate"
  value = {
    certificate_id = module.iot_core.certificate_id
    certificate_arn = module.iot_core.certificate_arn
    policy_name = module.iot_core.policy_name
  }
}

output "deployment_info" {
  description = "Thông tin deployment"
  value = {
    environment = var.environment
    region = var.aws_region
    project_name = var.project_name
  }
} 