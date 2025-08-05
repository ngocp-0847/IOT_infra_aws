# =============================================================================
# Enhanced IoT Core Module với Security Enhancements
# =============================================================================

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# =============================================================================
# 1. DEVICE IDENTITY & REGISTRY
# =============================================================================

# Enhanced Thing Type với security attributes
resource "aws_iot_thing_type" "sensor" {
  name = "${var.project_name}_sensor_${var.environment}"

  properties {
    description = "Secure IoT Sensor Device Type"
    searchable_attributes = [
      "device_id", 
      "sensor_type", 
      "firmware_version",
      "security_level",
      "last_seen"
    ]
  }

  tags = merge(var.tags, {
    SecurityLevel = "high"
    Environment   = var.environment
  })
}

# Thing Groups cho device management
resource "aws_iot_thing_group" "production_devices" {
  name = "${var.project_name}_production_${var.environment}"
  
  thing_group_properties {
    description = "Production IoT devices"
    attribute_payload {
      attributes = {
        Environment   = "production"
        SecurityLevel = "high"
        MonitoringEnabled = "true"
      }
    }
  }

  tags = var.tags
}

resource "aws_iot_thing_group" "quarantine_devices" {
  name = "${var.project_name}_quarantine_${var.environment}"
  
  thing_group_properties {
    description = "Quarantined devices with security issues"
    attribute_payload {
      attributes = {
        Status        = "quarantined"
        SecurityLevel = "restricted"
        AccessLevel   = "minimal"
      }
    }
  }

  tags = var.tags
}

# Device registry DynamoDB table
resource "aws_dynamodb_table" "device_registry" {
  name           = "${var.project_name}_device_registry_${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "deviceId"

  attribute {
    name = "deviceId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "lastSeen"
    type = "S"
  }

  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
  }

  global_secondary_index {
    name     = "LastSeenIndex"
    hash_key = "lastSeen"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.tags
}

# =============================================================================
# 2. ENHANCED POLICIES với LEAST PRIVILEGE
# =============================================================================

# Production device policy với least privilege
resource "aws_iot_policy" "production_device_policy" {
  name = "${var.project_name}_production_policy_${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
        Condition = {
          StringEquals = {
            "iot:Connection.Thing.ThingTypeName" = aws_iot_thing_type.sensor.name
          }
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/data/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/status/$${iot:Connection.Thing.ThingName}",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/telemetry/$${iot:Connection.Thing.ThingName}"
        ]
        Condition = {
          ForAllValues:StringLike = {
            "iot:Publish.Topic" = [
              "iot/data/$${iot:Connection.Thing.ThingName}/*",
              "iot/status/$${iot:Connection.Thing.ThingName}",
              "iot/telemetry/$${iot:Connection.Thing.ThingName}"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/iot/commands/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/iot/config/$${iot:Connection.Thing.ThingName}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/commands/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/config/$${iot:Connection.Thing.ThingName}"
        ]
      }
    ]
  })

  tags = var.tags
}

# Quarantine policy với limited access
resource "aws_iot_policy" "quarantine_policy" {
  name = "${var.project_name}_quarantine_policy_${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/quarantine/$${iot:Connection.Thing.ThingName}/status"
        ]
      }
    ]
  })

  tags = var.tags
}

# =============================================================================
# 3. ENHANCED TOPIC RULES với MESSAGE VALIDATION
# =============================================================================

# Validated data processing rule
resource "aws_iot_topic_rule" "validated_data_rule" {
  name        = "${var.project_name}_validated_data_rule_${var.environment}"
  description = "Process validated IoT messages with security checks"
  enabled     = true
  
  # Enhanced SQL với comprehensive validation
  sql = <<EOF
SELECT 
  deviceId,
  timestamp,
  temperature,
  humidity,
  batteryLevel,
  location,
  firmwareVersion,
  messageId
FROM 'iot/data/+/sensors' 
WHERE 
  temperature BETWEEN -50 AND 80 AND
  humidity BETWEEN 0 AND 100 AND
  batteryLevel BETWEEN 0 AND 100 AND
  deviceId <> '' AND
  timestamp > (timestamp() - 300000) AND
  length(deviceId) <= 50 AND
  messageId <> ''
EOF
  sql_version = "2016-03-23"

  # Send to SQS for processing
  sqs {
    queue_url = var.sqs_queue_url
    role_arn  = aws_iam_role.iot_sqs_role.arn
    use_base64 = false
  }

  # Send to CloudWatch for monitoring
  cloudwatch_logs {
    log_group_name = aws_cloudwatch_log_group.iot_data_logs.name
    role_arn      = aws_iam_role.iot_logging_role.arn
  }

  # Error handling
  error_action {
    cloudwatch_logs {
      log_group_name = aws_cloudwatch_log_group.iot_error_logs.name
      role_arn      = aws_iam_role.iot_logging_role.arn
    }
  }

  tags = var.tags
}

# Security events rule
resource "aws_iot_topic_rule" "security_events_rule" {
  name        = "${var.project_name}_security_events_rule_${var.environment}"
  description = "Handle security-related events and alerts"
  enabled     = true
  sql         = "SELECT * FROM 'iot/security/+'"
  sql_version = "2016-03-23"

  # Send security events to SNS for immediate alerting
  sns {
    target_arn = aws_sns_topic.security_alerts.arn
    role_arn   = aws_iam_role.iot_sns_role.arn
    message_format = "JSON"
  }

  # Also log security events
  cloudwatch_logs {
    log_group_name = aws_cloudwatch_log_group.iot_security_logs.name
    role_arn      = aws_iam_role.iot_logging_role.arn
  }

  tags = var.tags
}

# Real-time processing với rate limiting awareness
resource "aws_iot_topic_rule" "realtime_rule_enhanced" {
  name        = "${var.project_name}_realtime_enhanced_${var.environment}"
  description = "Enhanced real-time processing với security checks"
  enabled     = true
  
  sql = <<EOF
SELECT 
  *,
  timestamp() as processingTime,
  topic(3) as deviceId
FROM 'iot/realtime'
WHERE 
  get(*, "deviceId") <> '' AND
  get(*, "timestamp") > (timestamp() - 60000)
EOF
  sql_version = "2016-03-23"

  sqs {
    queue_url = var.sqs_queue_url
    role_arn  = aws_iam_role.iot_sqs_role.arn
    use_base64 = false
  }

  tags = var.tags
}

# =============================================================================
# 4. DEVICE DEFENDER SECURITY PROFILES
# =============================================================================

# Comprehensive security profile
resource "aws_iot_security_profile" "device_security_profile" {
  name = "${var.project_name}_security_profile_${var.environment}"
  description = "Comprehensive IoT device security monitoring"

  behaviors {
    name = "auth-failures"
    metric = "aws:num-authorization-failures"
    criteria {
      comparison_operator = "greater-than"
      value {
        count = 5
      }
      duration_seconds = 300
      consecutive_datapoints_to_alarm = 2
      consecutive_datapoints_to_clear = 2
    }
  }

  behaviors {
    name = "message-size"
    metric = "aws:message-byte-size"
    criteria {
      comparison_operator = "greater-than"
      value {
        count = 10240  # 10KB max message size
      }
      duration_seconds = 300
    }
  }

  behaviors {
    name = "connection-attempts"
    metric = "aws:num-connections-attempted"
    criteria {
      comparison_operator = "greater-than"
      value {
        count = 50
      }
      duration_seconds = 3600
    }
  }

  behaviors {
    name = "disconnect-rate"
    metric = "aws:num-disconnects"
    criteria {
      comparison_operator = "greater-than"
      value {
        count = 10
      }
      duration_seconds = 300
    }
  }

  behaviors {
    name = "listening-tcp-ports"
    metric = "aws:listening-tcp-ports"
    criteria {
      comparison_operator = "in-port-set"
      value {
        ports = [22, 23, 21, 20, 443, 80, 8883, 8443]
      }
    }
  }

  alert_targets {
    alert_target_arn = aws_sns_topic.security_alerts.arn
    role_arn = aws_iam_role.device_defender_role.arn
  }

  additional_metrics_to_retain_v2 {
    metric = "aws:all-bytes-in"
    metric_dimension {
      dimension_name = "sourceIp"
      operator = "IN_SET"
      string_values = ["*"]
    }
  }

  additional_metrics_to_retain_v2 {
    metric = "aws:all-bytes-out"
    metric_dimension {
      dimension_name = "sourceIp"
      operator = "IN_SET"
      string_values = ["*"]
    }
  }

  tags = var.tags
}

# Attach security profile to production devices
resource "aws_iot_security_profile_target" "production_target" {
  security_profile_name = aws_iot_security_profile.device_security_profile.name
  security_profile_target_arn = aws_iot_thing_group.production_devices.arn
}

# =============================================================================
# 5. CLOUDWATCH LOGGING & MONITORING
# =============================================================================

# CloudWatch log groups
resource "aws_cloudwatch_log_group" "iot_data_logs" {
  name              = "/aws/iot/${var.project_name}/data"
  retention_in_days = 30
  
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "iot_security_logs" {
  name              = "/aws/iot/${var.project_name}/security"
  retention_in_days = 90
  
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "iot_error_logs" {
  name              = "/aws/iot/${var.project_name}/errors"
  retention_in_days = 60
  
  tags = var.tags
}

# IoT logging configuration
resource "aws_iot_logging_options" "iot_logging" {
  default_log_level = "ERROR"
  disable_all_logs  = false
  
  role_arn = aws_iam_role.iot_logging_role.arn
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "high_connection_failures" {
  alarm_name          = "${var.project_name}-high-connection-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Connect.AuthError"
  namespace           = "AWS/IoT"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High number of authentication failures detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Protocol = "MQTT"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "unusual_data_volume" {
  alarm_name          = "${var.project_name}-unusual-data-volume"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PublishIn.Success"
  namespace           = "AWS/IoT"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "Unusual high data volume detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "device_defender_violations" {
  alarm_name          = "${var.project_name}-device-defender-violations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ViolationCount"
  namespace           = "AWS/IoTDeviceDefender"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Device Defender security violations detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    SecurityProfileName = aws_iot_security_profile.device_security_profile.name
  }

  tags = var.tags
}

# =============================================================================
# 6. SNS TOPIC cho SECURITY ALERTS
# =============================================================================

resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}_security_alerts_${var.environment}"
  
  tags = var.tags
}

resource "aws_sns_topic_policy" "security_alerts_policy" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIoTPublish"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# =============================================================================
# 7. IAM ROLES & POLICIES
# =============================================================================

# Enhanced IoT SQS Role
resource "aws_iam_role" "iot_sqs_role" {
  name = "${var.project_name}_iot_sqs_role_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "iot_sqs_policy" {
  name = "${var.project_name}_iot_sqs_policy_${var.environment}"
  role = aws_iam_role.iot_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queue_arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# IoT Logging Role
resource "aws_iam_role" "iot_logging_role" {
  name = "${var.project_name}_iot_logging_role_${var.environment}"

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

resource "aws_iam_role_policy" "iot_logging_policy" {
  name = "${var.project_name}_iot_logging_policy_${var.environment}"
  role = aws_iam_role.iot_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = [
          aws_cloudwatch_log_group.iot_data_logs.arn,
          aws_cloudwatch_log_group.iot_security_logs.arn,
          aws_cloudwatch_log_group.iot_error_logs.arn,
          "${aws_cloudwatch_log_group.iot_data_logs.arn}:*",
          "${aws_cloudwatch_log_group.iot_security_logs.arn}:*",
          "${aws_cloudwatch_log_group.iot_error_logs.arn}:*"
        ]
      }
    ]
  })
}

# IoT SNS Role
resource "aws_iam_role" "iot_sns_role" {
  name = "${var.project_name}_iot_sns_role_${var.environment}"

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

resource "aws_iam_role_policy" "iot_sns_policy" {
  name = "${var.project_name}_iot_sns_policy_${var.environment}"
  role = aws_iam_role.iot_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# Device Defender Role
resource "aws_iam_role" "device_defender_role" {
  name = "${var.project_name}_device_defender_role_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iotdevicedefender.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "device_defender_policy" {
  name = "${var.project_name}_device_defender_policy_${var.environment}"
  role = aws_iam_role.device_defender_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# =============================================================================
# 8. VPC ENDPOINTS (Optional)
# =============================================================================

# VPC endpoint for IoT Data (nếu enable private network)
resource "aws_vpc_endpoint" "iot_data" {
  count             = var.enable_private_network ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.iot.data"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.private_subnet_ids
  
  security_group_ids = [aws_security_group.iot_endpoint[0].id]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/Environment" = var.environment
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

# Security group for VPC endpoint
resource "aws_security_group" "iot_endpoint" {
  count       = var.enable_private_network ? 1 : 0
  name        = "${var.project_name}_iot_endpoint_sg_${var.environment}"
  description = "Security group for IoT VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS for IoT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "MQTT over TLS"
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}_iot_endpoint_sg_${var.environment}"
  })
}