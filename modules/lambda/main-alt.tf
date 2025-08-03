# =============================================================================
# Alternative Lambda Configuration - Sử dụng pre-built zip files
# =============================================================================

# Uncomment và replace main Lambda functions nếu muốn sử dụng approach này

/*
# Lambda Function cho Stream Processing - Pre-built zip approach
resource "aws_lambda_function" "stream_processor_alt" {
  filename         = "${path.module}/stream_processor.zip"
  function_name    = "${var.project_name}-stream-processor-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "stream_processor.handler"
  runtime         = var.runtime
  timeout         = 30
  memory_size     = 128
  
  # Sử dụng file hash để detect thay đổi
  source_code_hash = filebase64sha256("${path.module}/stream_processor.zip")

  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
  }

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      S3_BUCKET      = var.s3_bucket_name
    }
  }

  tags = var.tags
  
  # Depends on zip file existence
  depends_on = [null_resource.build_lambda]
}

# Lambda Function cho Query Handler - Pre-built zip approach
resource "aws_lambda_function" "query_handler_alt" {
  filename         = "${path.module}/query_handler.zip"
  function_name    = "${var.project_name}-query-handler-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "query_handler.handler"
  runtime         = var.runtime
  timeout         = 30
  memory_size     = 128
  
  # Sử dụng file hash để detect thay đổi
  source_code_hash = filebase64sha256("${path.module}/query_handler.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.tags
  
  # Depends on zip file existence
  depends_on = [null_resource.build_lambda]
}

# Null resource để trigger build khi source code thay đổi
resource "null_resource" "build_lambda" {
  # Triggers khi source files thay đổi
  triggers = {
    stream_processor_hash = filemd5("${path.module}/lambda/stream_processor.py")
    query_handler_hash    = filemd5("${path.module}/lambda/query_handler.py")
  }

  # Build Lambda functions khi có thay đổi
  provisioner "local-exec" {
    command = "cd ${path.module} && ./build.sh"
  }
}
*/