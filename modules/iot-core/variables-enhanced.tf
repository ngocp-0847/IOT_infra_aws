# =============================================================================
# Enhanced Variables cho IoT Core Security Module
# =============================================================================

# Basic variables (existing)
variable "environment" {
  description = "Môi trường triển khai (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Tên project"
  type        = string
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
}

variable "sqs_queue_url" {
  description = "URL của SQS queue"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN của SQS queue"
  type        = string
}

variable "tags" {
  description = "Tags chung cho tất cả resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Security Enhancement Variables
# =============================================================================

variable "enable_device_defender" {
  description = "Enable AWS IoT Device Defender monitoring"
  type        = bool
  default     = true
}

variable "enable_enhanced_logging" {
  description = "Enable enhanced CloudWatch logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "security_log_retention_days" {
  description = "Security logs retention period in days"
  type        = number
  default     = 90
}

variable "max_message_size_kb" {
  description = "Maximum allowed message size in KB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_message_size_kb > 0 && var.max_message_size_kb <= 128
    error_message = "Message size must be between 1 and 128 KB."
  }
}

variable "auth_failure_threshold" {
  description = "Maximum authentication failures before alarm"
  type        = number
  default     = 5
  
  validation {
    condition     = var.auth_failure_threshold > 0 && var.auth_failure_threshold <= 100
    error_message = "Auth failure threshold must be between 1 and 100."
  }
}

variable "connection_rate_limit" {
  description = "Maximum connections per hour per device"
  type        = number
  default     = 50
  
  validation {
    condition     = var.connection_rate_limit > 0 && var.connection_rate_limit <= 1000
    error_message = "Connection rate limit must be between 1 and 1000."
  }
}

# =============================================================================
# Device Management Variables
# =============================================================================

variable "device_types" {
  description = "List of supported device types"
  type        = list(string)
  default     = ["temperature_sensor", "humidity_sensor", "motion_sensor"]
}

variable "firmware_versions" {
  description = "Supported firmware versions"
  type        = map(string)
  default = {
    minimum_supported = "1.0.0"
    recommended      = "2.1.0"
    latest          = "2.1.0"
  }
}

variable "device_security_levels" {
  description = "Device security classification levels"
  type        = list(string)
  default     = ["low", "medium", "high", "critical"]
}

# =============================================================================
# Network Security Variables
# =============================================================================

variable "enable_private_network" {
  description = "Enable VPC endpoints for private network access"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for private network access (required if enable_private_network is true)"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR block (required if enable_private_network is true)"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for VPC endpoints (required if enable_private_network is true)"
  type        = list(string)
  default     = []
}

variable "allowed_tcp_ports" {
  description = "Allowed TCP ports for device connections"
  type        = list(number)
  default     = [443, 8883, 8443]
}

# =============================================================================
# Certificate & Authentication Variables
# =============================================================================

variable "certificate_validity_days" {
  description = "Certificate validity period in days"
  type        = number
  default     = 365
  
  validation {
    condition     = var.certificate_validity_days >= 30 && var.certificate_validity_days <= 3650
    error_message = "Certificate validity must be between 30 and 3650 days (10 years)."
  }
}

variable "enable_certificate_rotation" {
  description = "Enable automatic certificate rotation"
  type        = bool
  default     = true
}

variable "certificate_rotation_days" {
  description = "Days before expiration to rotate certificates"
  type        = number
  default     = 30
  
  validation {
    condition     = var.certificate_rotation_days >= 7 && var.certificate_rotation_days <= 90
    error_message = "Certificate rotation days must be between 7 and 90."
  }
}

variable "enable_custom_authorizer" {
  description = "Enable custom authorizer for advanced authentication"
  type        = bool
  default     = false
}

variable "custom_authorizer_token_key" {
  description = "Token key name for custom authorizer"
  type        = string
  default     = "authToken"
}

# =============================================================================
# Monitoring & Alerting Variables
# =============================================================================

variable "alert_email_endpoints" {
  description = "Email addresses for security alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = length(var.alert_email_endpoints) == 0 || alltrue([
      for email in var.alert_email_endpoints : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "alert_sms_endpoints" {
  description = "SMS numbers for critical security alerts"
  type        = list(string)
  default     = []
}

variable "enable_security_metrics" {
  description = "Enable detailed security metrics collection"
  type        = bool
  default     = true
}

variable "metrics_retention_days" {
  description = "Custom metrics retention period in days"
  type        = number
  default     = 90
}

# =============================================================================
# Compliance & Audit Variables
# =============================================================================

variable "enable_audit_logging" {
  description = "Enable comprehensive audit logging"
  type        = bool
  default     = true
}

variable "compliance_mode" {
  description = "Compliance standard to follow (none, hipaa, pci, soc2)"
  type        = string
  default     = "none"
  
  validation {
    condition     = contains(["none", "hipaa", "pci", "soc2"], var.compliance_mode)
    error_message = "Compliance mode must be one of: none, hipaa, pci, soc2."
  }
}

variable "data_classification" {
  description = "Data classification level (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"
  
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be one of: public, internal, confidential, restricted."
  }
}

# =============================================================================
# Performance & Scaling Variables
# =============================================================================

variable "max_concurrent_connections" {
  description = "Maximum concurrent device connections"
  type        = number
  default     = 10000
  
  validation {
    condition     = var.max_concurrent_connections >= 1 && var.max_concurrent_connections <= 100000
    error_message = "Max concurrent connections must be between 1 and 100,000."
  }
}

variable "message_rate_per_second" {
  description = "Maximum messages per second per device"
  type        = number
  default     = 10
  
  validation {
    condition     = var.message_rate_per_second >= 1 && var.message_rate_per_second <= 1000
    error_message = "Message rate must be between 1 and 1000 per second."
  }
}

variable "enable_message_compression" {
  description = "Enable message compression to optimize bandwidth"
  type        = bool
  default     = true
}

# =============================================================================
# Environment-specific Overrides
# =============================================================================

variable "environment_config" {
  description = "Environment-specific configuration overrides"
  type = object({
    log_level                = optional(string, "INFO")
    enable_debug_logging     = optional(bool, false)
    security_scan_frequency  = optional(string, "daily")
    backup_retention_days    = optional(number, 30)
    enable_cross_region_backup = optional(bool, false)
  })
  default = {}
}

# =============================================================================
# Integration Variables
# =============================================================================

variable "external_sns_topics" {
  description = "External SNS topics for integration"
  type = map(object({
    arn         = string
    description = string
    alerts      = list(string)
  }))
  default = {}
}

variable "webhook_endpoints" {
  description = "Webhook endpoints for external integrations"
  type = map(object({
    url         = string
    method      = string
    headers     = map(string)
    auth_type   = string
    description = string
  }))
  default = {}
}

# =============================================================================
# Feature Flags
# =============================================================================

variable "feature_flags" {
  description = "Feature flags for experimental or optional features"
  type = object({
    enable_ml_anomaly_detection    = optional(bool, false)
    enable_predictive_maintenance  = optional(bool, false)
    enable_edge_analytics         = optional(bool, false)
    enable_blockchain_integration = optional(bool, false)
    enable_quantum_encryption     = optional(bool, false)
  })
  default = {}
}