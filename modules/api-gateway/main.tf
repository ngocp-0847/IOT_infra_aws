# =============================================================================
# API Gateway Module
# =============================================================================

# API Gateway
resource "aws_apigatewayv2_api" "iot_api" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "API Gateway cho IoT Platform"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_origins     = ["*"]
    expose_headers    = ["*"]
    max_age          = 300
  }

  tags = var.tags
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.iot_api.id
  name   = var.environment
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = var.tags
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.iot_api.id

  integration_type   = "AWS_PROXY"
  integration_uri    = var.lambda_function_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Lambda Permission
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.iot_api.execution_arn}/*/*"
}

# Routes
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.iot_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "devices" {
  api_id    = aws_apigatewayv2_api.iot_api.id
  route_key = "GET /devices"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "device_data" {
  api_id    = aws_apigatewayv2_api.iot_api.id
  route_key = "GET /devices/{device_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Default route
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.iot_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
} 