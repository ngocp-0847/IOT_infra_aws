# =============================================================================
# Lambda Module using Container Images from ECR (no local build by Terraform)
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
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# ECR repositories for Lambda images
resource "aws_ecr_repository" "stream" {
  name = "${var.project_name}-stream-processor-${var.environment}"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_repository" "query" {
  name = "${var.project_name}-query-handler-${var.environment}"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# Lambda Function cho Stream Processing - Container Image
resource "aws_lambda_function" "stream_processor" {
  function_name = "${var.project_name}-stream-processor-${var.environment}"
  role          = aws_iam_role.lambda_role.arn

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.stream.repository_url}:${var.stream_processor_image_tag}"

  timeout     = var.timeout
  memory_size = var.memory_size

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

# Lambda Function cho Query Handler - Container Image
resource "aws_lambda_function" "query_handler" {
  function_name = "${var.project_name}-query-handler-${var.environment}"
  role          = aws_iam_role.lambda_role.arn

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.query.repository_url}:${var.query_handler_image_tag}"

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.tags
}

# Event Source Mapping cho SQS
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.stream_processor.function_name
  batch_size       = 10
  maximum_batching_window_in_seconds = 5
}

# CloudWatch Log Groups - Free Tier Optimized
resource "aws_cloudwatch_log_group" "stream_processor" {
  name              = "/aws/lambda/${aws_lambda_function.stream_processor.function_name}"
  retention_in_days = 3

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "query_handler" {
  name              = "/aws/lambda/${aws_lambda_function.query_handler.function_name}"
  retention_in_days = 3

  tags = var.tags
}