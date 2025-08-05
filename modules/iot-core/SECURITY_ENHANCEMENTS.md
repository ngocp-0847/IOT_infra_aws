# Cải Tiến Bảo Mật IoT Core - Chống Hack

## 🔍 Phân Tích Bảo Mật Hiện Tại

### Các Lỗ Hổng Bảo Mật Được Phát Hiện

1. **IoT Policy Quá Rộng** ❌
   - `Resource = "*"` cho phép thiết bị truy cập mọi topic/resource
   - Không có phân quyền theo từng thiết bị
   - Risk: Device compromise có thể ảnh hưởng toàn hệ thống

2. **Quản Lý Certificate Yếu** ❌
   - Chỉ có test certificate cho development
   - Không có device registry hay lifecycle management
   - Risk: Certificate không thể thu hồi khi device bị hack

3. **Topic Rules Không Filter** ❌
   - Accept tất cả message từ `iot/data/#`
   - Không validate message format/content
   - Risk: Malicious payload injection

4. **Thiếu Monitoring/Auditing** ❌
   - Không có CloudWatch logs
   - Thiếu Device Defender
   - Risk: Không phát hiện được intrusion

5. **Không Có Rate Limiting** ❌
   - Thiếu throttling cho connections/messages
   - Risk: DoS attacks, resource exhaustion

6. **Authentication Đơn Giản** ❌
   - Chỉ dựa vào X.509 certificate
   - Không có multi-factor authentication
   - Risk: Credential theft

## 🛡️ Đề Xuất Cải Tiến Bảo Mật

### 1. Zero Trust Architecture

#### 1.1 Device Identity & Registry
```hcl
# Device registry với unique identity
resource "aws_iot_thing" "sensor_device" {
  count = var.device_count
  name  = "${var.project_name}_device_${count.index}_${var.environment}"
  
  thing_type_name = aws_iot_thing_type.sensor.name
  
  attributes = {
    DeviceSerialNumber = var.device_serial_numbers[count.index]
    FirmwareVersion    = var.firmware_version
    DeviceModel        = var.device_model
    ManufactureDate    = var.manufacture_date
  }
}

# Certificate cho từng device
resource "aws_iot_certificate" "device_cert" {
  count  = var.device_count
  active = true
  
  lifecycle {
    create_before_destroy = true
  }
}

# Policy riêng cho từng device type
resource "aws_iot_policy" "sensor_policy" {
  name = "${var.project_name}_sensor_policy_${var.environment}"

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
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/data/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/status/$${iot:Connection.Thing.ThingName}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/iot/commands/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/iot/commands/$${iot:Connection.Thing.ThingName}/*"
        ]
      }
    ]
  })
}
```

#### 1.2 Enhanced Thing Groups với Dynamic Membership
```hcl
# Thing groups cho phân loại devices
resource "aws_iot_thing_group" "production_devices" {
  name = "${var.project_name}_production_${var.environment}"
  
  thing_group_properties {
    description = "Production IoT devices"
    attribute_payload {
      attributes = {
        Environment = "production"
        SecurityLevel = "high"
      }
    }
  }
}

resource "aws_iot_thing_group" "quarantine_devices" {
  name = "${var.project_name}_quarantine_${var.environment}"
  
  thing_group_properties {
    description = "Quarantined devices with security issues"
    attribute_payload {
      attributes = {
        Status = "quarantined"
        SecurityLevel = "restricted"
      }
    }
  }
}

# Policy for quarantined devices (limited access)
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
}
```

### 2. Device Defender & Monitoring

#### 2.1 Security Profiles
```hcl
# Security profile để monitor device behavior
resource "aws_iot_security_profile" "device_security_profile" {
  name = "${var.project_name}_security_profile_${var.environment}"
  description = "Monitor IoT device security metrics"

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
        count = 10240  # 10KB
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
      duration_seconds = 3600  # 1 hour
    }
  }

  alert_targets {
    alert_target_arn = aws_sns_topic.security_alerts.arn
    role_arn = aws_iam_role.device_defender_role.arn
  }

  tags = var.tags
}

# Attach security profile to thing group
resource "aws_iot_security_profile_target" "production_target" {
  security_profile_name = aws_iot_security_profile.device_security_profile.name
  security_profile_target_arn = aws_iot_thing_group.production_devices.arn
}
```

#### 2.2 CloudWatch Logging & Metrics
```hcl
# CloudWatch log group for IoT logs
resource "aws_cloudwatch_log_group" "iot_logs" {
  name              = "/aws/iot/${var.project_name}"
  retention_in_days = 30
  
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
  alarm_description   = "High number of authentication failures"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    Protocol = "MQTT"
  }
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
  alarm_description   = "Unusual high data volume"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}
```

### 3. Advanced Topic Rules với Validation

#### 3.1 Message Validation & Filtering
```hcl
# Topic rule với message validation
resource "aws_iot_topic_rule" "validated_data_rule" {
  name        = "${var.project_name}_validated_data_rule_${var.environment}"
  description = "Process validated IoT messages"
  enabled     = true
  
  # Enhanced SQL với validation
  sql = <<EOF
SELECT 
  deviceId,
  timestamp,
  temperature,
  humidity,
  batteryLevel,
  location
FROM 'iot/data/+/sensors' 
WHERE 
  temperature BETWEEN -50 AND 80 AND
  humidity BETWEEN 0 AND 100 AND
  batteryLevel BETWEEN 0 AND 100 AND
  deviceId <> '' AND
  timestamp > (timestamp() - 300000)
EOF
  sql_version = "2016-03-23"

  # Send to Lambda for advanced validation
  lambda {
    function_arn = aws_lambda_function.message_validator.arn
  }

  # Also send to SQS for processing
  sqs {
    queue_url = var.sqs_queue_url
    role_arn  = aws_iam_role.iot_sqs_role.arn
    use_base64 = false
  }

  # Error handling
  error_action {
    lambda {
      function_arn = aws_lambda_function.error_handler.arn
    }
  }

  tags = var.tags
}

# Separate rule for security events
resource "aws_iot_topic_rule" "security_events_rule" {
  name        = "${var.project_name}_security_events_rule_${var.environment}"
  description = "Handle security-related events"
  enabled     = true
  sql         = "SELECT * FROM 'iot/security/+'"
  sql_version = "2016-03-23"

  # Send security events to separate SNS topic
  sns {
    target_arn = aws_sns_topic.security_alerts.arn
    role_arn   = aws_iam_role.iot_sns_role.arn
  }

  tags = var.tags
}
```

### 4. Certificate Lifecycle Management

#### 4.1 Certificate Rotation
```hcl
# Lambda for certificate rotation
resource "aws_lambda_function" "cert_rotation" {
  filename      = "cert_rotation.zip"
  function_name = "${var.project_name}_cert_rotation_${var.environment}"
  role          = aws_iam_role.cert_rotation_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      IOT_ENDPOINT = data.aws_iot_endpoint.current.endpoint_address
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }
}

# EventBridge rule for certificate expiration
resource "aws_cloudwatch_event_rule" "cert_expiration" {
  name        = "${var.project_name}_cert_expiration_${var.environment}"
  description = "Trigger certificate rotation before expiration"
  
  schedule_expression = "rate(7 days)"  # Check weekly
}

resource "aws_cloudwatch_event_target" "cert_rotation_target" {
  rule      = aws_cloudwatch_event_rule.cert_expiration.name
  target_id = "CertRotationTarget"
  arn       = aws_lambda_function.cert_rotation.arn
}
```

### 5. Network Security Enhancements

#### 5.1 VPC Endpoints (Private Network Access)
```hcl
# VPC endpoint for IoT Core (if using private network)
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
```

### 6. Custom Authorizers

#### 6.1 Advanced Authentication
```hcl
# Custom authorizer Lambda
resource "aws_lambda_function" "custom_authorizer" {
  filename      = "custom_authorizer.zip"
  function_name = "${var.project_name}_custom_authorizer_${var.environment}"
  role          = aws_iam_role.authorizer_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      DEVICE_REGISTRY_TABLE = aws_dynamodb_table.device_registry.name
      SECURITY_TOKEN_SECRET = var.security_token_secret
    }
  }
}

# Custom authorizer
resource "aws_iot_authorizer" "custom_auth" {
  name                    = "${var.project_name}_custom_authorizer_${var.environment}"
  authorizer_function_arn = aws_lambda_function.custom_authorizer.arn
  status                  = "ACTIVE"
  token_key_name          = "authToken"
  token_signing_public_keys = {
    "key1" = var.public_key_1
    "key2" = var.public_key_2
  }
}

# Device registry table
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

  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = var.tags
}
```

### 7. Incident Response & Recovery

#### 7.1 Automated Response
```hcl
# SNS topic for security alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}_security_alerts_${var.environment}"
  
  tags = var.tags
}

# Lambda for automated incident response
resource "aws_lambda_function" "incident_response" {
  filename      = "incident_response.zip"
  function_name = "${var.project_name}_incident_response_${var.environment}"
  role          = aws_iam_role.incident_response_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 300

  environment {
    variables = {
      IOT_ENDPOINT = data.aws_iot_endpoint.current.endpoint_address
      QUARANTINE_GROUP = aws_iot_thing_group.quarantine_devices.arn
      QUARANTINE_POLICY = aws_iot_policy.quarantine_policy.name
    }
  }
}

# SNS subscription for incident response
resource "aws_sns_topic_subscription" "incident_response" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.incident_response.arn
}
```

## 🔧 Implementation Roadmap

### Phase 1: Foundation (1-2 tuần)
1. ✅ Implement device registry và unique identities
2. ✅ Create least-privilege policies
3. ✅ Setup CloudWatch logging
4. ✅ Deploy basic monitoring

### Phase 2: Advanced Security (2-3 tuần)
1. ✅ Deploy Device Defender
2. ✅ Implement message validation
3. ✅ Setup certificate lifecycle management
4. ✅ Create security profiles

### Phase 3: Zero Trust (3-4 tuần)
1. ✅ Deploy custom authorizers
2. ✅ Implement VPC endpoints
3. ✅ Advanced threat detection
4. ✅ Automated incident response

### Phase 4: Compliance & Audit (1-2 tuần)
1. ✅ Setup comprehensive logging
2. ✅ Create compliance reports
3. ✅ Security penetration testing
4. ✅ Documentation update

## 📊 Security Metrics & KPIs

### Metrics để Monitor
- Authentication failure rate
- Abnormal message patterns
- Device connection anomalies
- Certificate expiration status
- Network traffic patterns
- Security incident response time

### Alerting Thresholds
- Auth failures: > 5 trong 5 phút
- Message size: > 10KB
- Connection rate: > 50/hour per device
- Certificate expiry: < 30 days

## 🚨 Incident Response Plan

### 1. Detection
- CloudWatch alarms
- Device Defender alerts
- Custom security rules

### 2. Classification
- Low: Unusual patterns
- Medium: Multiple failed auths
- High: Confirmed compromise
- Critical: Mass device compromise

### 3. Response Actions
- **Low**: Log và monitor
- **Medium**: Increase monitoring, notify admin
- **High**: Quarantine device, revoke certificates
- **Critical**: Emergency response, isolate all affected devices

### 4. Recovery
- Root cause analysis
- Certificate reissuance
- Device firmware update
- Policy updates

## 💡 Best Practices Summary

1. **Never Trust, Always Verify** - Zero Trust principles
2. **Principle of Least Privilege** - Minimum required permissions
3. **Defense in Depth** - Multiple security layers
4. **Continuous Monitoring** - Real-time threat detection
5. **Incident Preparedness** - Automated response procedures
6. **Regular Security Reviews** - Quarterly assessments
7. **Certificate Hygiene** - Regular rotation và validation
8. **Network Segmentation** - Isolate IoT traffic

## 📚 References

- [AWS IoT Security Best Practices](https://docs.aws.amazon.com/iot/latest/developerguide/security-best-practices.html)
- [Zero Trust IoT with AWS](https://aws.amazon.com/blogs/iot/how-to-implement-zero-trust-iot-solutions-with-aws-iot/)
- [IoT Device Defender](https://docs.aws.amazon.com/iot/latest/developerguide/device-defender.html)
- [NIST IoT Security Guidelines](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-213.pdf)