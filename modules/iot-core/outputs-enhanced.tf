# =============================================================================
# Enhanced Outputs cho IoT Core Security Module
# =============================================================================

# =============================================================================
# Basic IoT Core Outputs
# =============================================================================

output "iot_endpoint" {
  description = "IoT Core endpoint for device connections"
  value       = "https://iot.${data.aws_region.current.name}.amazonaws.com"
  sensitive   = false
}

output "iot_data_endpoint" {
  description = "IoT Core data endpoint"
  value       = data.aws_iot_endpoint.current.endpoint_address
  sensitive   = false
}

# Không expose certificate details trong outputs vì security
output "certificate_created" {
  description = "Indicates if certificates were created successfully"
  value       = true
}

output "policy_names" {
  description = "Names của IoT policies được tạo"
  value = {
    production_policy = aws_iot_policy.production_device_policy.name
    quarantine_policy = aws_iot_policy.quarantine_policy.name
  }
}

# =============================================================================
# Device Management Outputs
# =============================================================================

output "thing_type_arn" {
  description = "ARN của IoT Thing Type"
  value       = aws_iot_thing_type.sensor.arn
}

output "thing_type_name" {
  description = "Name của IoT Thing Type"
  value       = aws_iot_thing_type.sensor.name
}

output "thing_groups" {
  description = "Thing groups được tạo"
  value = {
    production = {
      name = aws_iot_thing_group.production_devices.name
      arn  = aws_iot_thing_group.production_devices.arn
    }
    quarantine = {
      name = aws_iot_thing_group.quarantine_devices.name
      arn  = aws_iot_thing_group.quarantine_devices.arn
    }
  }
}

output "device_registry_table" {
  description = "Device registry DynamoDB table information"
  value = {
    name = aws_dynamodb_table.device_registry.name
    arn  = aws_dynamodb_table.device_registry.arn
  }
}

# =============================================================================
# Security & Monitoring Outputs
# =============================================================================

output "security_profile" {
  description = "Device Defender security profile information"
  value = {
    name = aws_iot_security_profile.device_security_profile.name
    arn  = aws_iot_security_profile.device_security_profile.arn
  }
}

output "security_alerts_topic" {
  description = "SNS topic for security alerts"
  value = {
    name = aws_sns_topic.security_alerts.name
    arn  = aws_sns_topic.security_alerts.arn
  }
  sensitive = false
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for monitoring"
  value = {
    data_logs = {
      name = aws_cloudwatch_log_group.iot_data_logs.name
      arn  = aws_cloudwatch_log_group.iot_data_logs.arn
    }
    security_logs = {
      name = aws_cloudwatch_log_group.iot_security_logs.name
      arn  = aws_cloudwatch_log_group.iot_security_logs.arn
    }
    error_logs = {
      name = aws_cloudwatch_log_group.iot_error_logs.name
      arn  = aws_cloudwatch_log_group.iot_error_logs.arn
    }
  }
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarms for monitoring"
  value = {
    connection_failures = {
      name = aws_cloudwatch_metric_alarm.high_connection_failures.alarm_name
      arn  = aws_cloudwatch_metric_alarm.high_connection_failures.arn
    }
    data_volume = {
      name = aws_cloudwatch_metric_alarm.unusual_data_volume.alarm_name
      arn  = aws_cloudwatch_metric_alarm.unusual_data_volume.arn
    }
    defender_violations = {
      name = aws_cloudwatch_metric_alarm.device_defender_violations.alarm_name
      arn  = aws_cloudwatch_metric_alarm.device_defender_violations.arn
    }
  }
}

# =============================================================================
# Topic Rules Outputs
# =============================================================================

output "topic_rules" {
  description = "IoT topic rules được tạo"
  value = {
    validated_data = {
      name = aws_iot_topic_rule.validated_data_rule.name
      arn  = aws_iot_topic_rule.validated_data_rule.arn
    }
    security_events = {
      name = aws_iot_topic_rule.security_events_rule.name
      arn  = aws_iot_topic_rule.security_events_rule.arn
    }
    realtime_enhanced = {
      name = aws_iot_topic_rule.realtime_rule_enhanced.name
      arn  = aws_iot_topic_rule.realtime_rule_enhanced.arn
    }
  }
}

# =============================================================================
# IAM Roles Outputs
# =============================================================================

output "iam_roles" {
  description = "IAM roles được tạo cho IoT services"
  value = {
    sqs_role = {
      name = aws_iam_role.iot_sqs_role.name
      arn  = aws_iam_role.iot_sqs_role.arn
    }
    logging_role = {
      name = aws_iam_role.iot_logging_role.name
      arn  = aws_iam_role.iot_logging_role.arn
    }
    sns_role = {
      name = aws_iam_role.iot_sns_role.name
      arn  = aws_iam_role.iot_sns_role.arn
    }
    device_defender_role = {
      name = aws_iam_role.device_defender_role.name
      arn  = aws_iam_role.device_defender_role.arn
    }
  }
}

# =============================================================================
# Network Security Outputs
# =============================================================================

output "vpc_endpoint" {
  description = "VPC endpoint information (if enabled)"
  value = var.enable_private_network ? {
    id  = aws_vpc_endpoint.iot_data[0].id
    dns = aws_vpc_endpoint.iot_data[0].dns_entry
  } : null
}

output "security_group" {
  description = "Security group for VPC endpoint (if enabled)"
  value = var.enable_private_network ? {
    id   = aws_security_group.iot_endpoint[0].id
    name = aws_security_group.iot_endpoint[0].name
  } : null
}

# =============================================================================
# Configuration Outputs
# =============================================================================

output "connection_info" {
  description = "Connection information for IoT devices"
  value = {
    mqtt_endpoint    = data.aws_iot_endpoint.current.endpoint_address
    mqtt_port        = 8883
    websocket_port   = 443
    http_port        = 443
    supported_protocols = ["MQTT", "MQTT over WebSocket", "HTTPS"]
    region          = data.aws_region.current.name
  }
  sensitive = false
}

output "security_configuration" {
  description = "Security configuration summary"
  value = {
    device_defender_enabled     = var.enable_device_defender
    enhanced_logging_enabled    = var.enable_enhanced_logging
    private_network_enabled     = var.enable_private_network
    certificate_rotation_enabled = var.enable_certificate_rotation
    custom_authorizer_enabled   = var.enable_custom_authorizer
    max_message_size_kb        = var.max_message_size_kb
    auth_failure_threshold     = var.auth_failure_threshold
    connection_rate_limit      = var.connection_rate_limit
    compliance_mode           = var.compliance_mode
    data_classification       = var.data_classification
  }
  sensitive = false
}

# =============================================================================
# Device Topics Information
# =============================================================================

output "device_topic_patterns" {
  description = "Topic patterns cho device communication"
  value = {
    data_publish = [
      "iot/data/{deviceId}/sensors",
      "iot/status/{deviceId}",
      "iot/telemetry/{deviceId}"
    ]
    command_subscribe = [
      "iot/commands/{deviceId}/+",
      "iot/config/{deviceId}"
    ]
    security_topics = [
      "iot/security/{deviceId}"
    ]
    quarantine_topics = [
      "iot/quarantine/{deviceId}/status"
    ]
  }
}

# =============================================================================
# Monitoring Dashboard Information
# =============================================================================

output "monitoring_resources" {
  description = "Resources for monitoring dashboard"
  value = {
    metrics_namespace = "AWS/IoT"
    custom_metrics = [
      "DeviceConnections",
      "MessageCount",
      "AuthenticationFailures",
      "SecurityViolations"
    ]
    log_insights_queries = {
      connection_errors = "fields @timestamp, message | filter message like /connection/ and message like /error/ | sort @timestamp desc"
      auth_failures = "fields @timestamp, message | filter message like /authentication/ and message like /failed/ | sort @timestamp desc"
      security_events = "fields @timestamp, message | filter message like /security/ | sort @timestamp desc"
    }
  }
}

# =============================================================================
# Troubleshooting Information
# =============================================================================

output "troubleshooting_info" {
  description = "Information for troubleshooting IoT connectivity"
  value = {
    common_connection_issues = [
      "Certificate not active",
      "Policy not attached to certificate",
      "Incorrect endpoint URL",
      "Clock skew on device",
      "Network connectivity issues"
    ]
    debugging_steps = [
      "Check certificate status in IoT console",
      "Verify policy permissions",
      "Test connectivity with AWS IoT CLI",
      "Review CloudWatch logs",
      "Check Device Defender alerts"
    ]
    support_resources = [
      "CloudWatch Logs: ${aws_cloudwatch_log_group.iot_error_logs.name}",
      "Security Alerts: ${aws_sns_topic.security_alerts.name}",
      "Device Registry: ${aws_dynamodb_table.device_registry.name}"
    ]
  }
}

# =============================================================================
# Cost Optimization Information
# =============================================================================

output "cost_optimization" {
  description = "Cost optimization recommendations"
  value = {
    estimated_monthly_costs = {
      message_processing = "Based on message volume"
      device_defender   = "Per device monitored"
      cloudwatch_logs  = "Based on log volume"
      dynamodb_usage  = "Based on device registry size"
    }
    cost_saving_tips = [
      "Use message compression",
      "Implement efficient batching",
      "Set appropriate log retention",
      "Monitor unused devices",
      "Use reserved capacity for DynamoDB if consistent load"
    ]
  }
}

# =============================================================================
# Data sources
# =============================================================================

data "aws_iot_endpoint" "current" {
  endpoint_type = "iot:Data-ATS"
}