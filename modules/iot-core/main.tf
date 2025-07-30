# =============================================================================
# IoT Core Module
# =============================================================================

# IoT Policy
resource "aws_iot_policy" "iot_policy" {
  name = "${var.project_name}-iot-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = "*"
      }
    ]
  })
}

# IoT Topic Rule
resource "aws_iot_topic_rule" "kinesis_rule" {
  name        = "${var.project_name}-kinesis-rule-${var.environment}"
  description = "Forward IoT messages to Kinesis"
  enabled     = true
  sql         = "SELECT * FROM 'iot/data'"
  sql_version = "2016-03-23"

  kinesis {
    stream_name = var.kinesis_stream_arn
    partition_key = "$${device_id}"
    role_arn = aws_iam_role.iot_kinesis_role.arn
  }

  tags = var.tags
}

# IAM Role cho IoT Core
resource "aws_iam_role" "iot_kinesis_role" {
  name = "${var.project_name}-iot-kinesis-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy cho IoT Core
resource "aws_iam_role_policy" "iot_kinesis_policy" {
  name = "${var.project_name}-iot-kinesis-policy-${var.environment}"
  role = aws_iam_role.iot_kinesis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord"
        ]
        Resource = var.kinesis_stream_arn
      }
    ]
  })
}

# IoT Thing Type
resource "aws_iot_thing_type" "sensor" {
  name = "${var.project_name}-sensor-${var.environment}"

  properties {
    description = "IoT Sensor Device Type"
    searchable_attributes = ["device_id", "sensor_type"]
  }

  tags = var.tags
}

# IoT Certificate (for testing)
resource "aws_iot_certificate" "test_cert" {
  active = true
}

# IoT Policy Attachment
resource "aws_iot_policy_attachment" "test_cert_policy" {
  policy = aws_iot_policy.iot_policy.name
  target = aws_iot_certificate.test_cert.arn
} 