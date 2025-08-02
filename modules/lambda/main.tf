# =============================================================================
# Lambda Module cho IoT Platform - Free Tier Optimized
# =============================================================================

# IAM Role cho Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy cho Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ]
        Resource = var.kinesis_stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function cho Stream Processing - Free Tier Optimized
resource "aws_lambda_function" "stream_processor" {
  filename         = data.archive_file.stream_processor.output_path
  function_name    = "${var.project_name}-stream-processor-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = 30  # Giảm timeout để tiết kiệm GB-seconds
  memory_size     = 128  # Giảm memory để tiết kiệm Free Tier GB-seconds

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
}

# Lambda Function cho Query Handler - Free Tier Optimized
resource "aws_lambda_function" "query_handler" {
  filename         = data.archive_file.query_handler.output_path
  function_name    = "${var.project_name}-query-handler-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = 30  # Giảm timeout
  memory_size     = 128  # Giảm memory để tiết kiệm

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.tags
}

# Event Source Mapping cho Kinesis
resource "aws_lambda_event_source_mapping" "kinesis_mapping" {
  event_source_arn  = var.kinesis_stream_arn
  function_name     = aws_lambda_function.stream_processor.function_name
  starting_position = "LATEST"
  batch_size        = 100  # Tối ưu batch size cho Free Tier
}

# CloudWatch Log Groups - Free Tier Optimized
resource "aws_cloudwatch_log_group" "stream_processor" {
  name              = "/aws/lambda/${aws_lambda_function.stream_processor.function_name}"
  retention_in_days = 3  # Giảm retention để tiết kiệm CloudWatch costs

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "query_handler" {
  name              = "/aws/lambda/${aws_lambda_function.query_handler.function_name}"
  retention_in_days = 3  # Giảm retention

  tags = var.tags
}

# Archive files cho Lambda code
data "archive_file" "stream_processor" {
  type        = "zip"
  output_path = "${path.module}/stream_processor.zip"
  source {
    content = file("${path.module}/lambda/stream_processor.py")
    filename = "index.py"
  }
}

data "archive_file" "query_handler" {
  type        = "zip"
  output_path = "${path.module}/query_handler.zip"
  source {
    content = file("${path.module}/lambda/query_handler.py")
    filename = "index.py"
  }
} 