# Hướng Dẫn Triển Khai Enhanced IoT Security

## 🚀 Quick Start Guide

### Bước 1: Backup Cấu Hình Hiện Tại
```bash
# Backup terraform state
terraform state pull > backup-state-$(date +%Y%m%d).json

# Backup current configuration files
cp modules/iot-core/main.tf modules/iot-core/main-backup.tf
cp modules/iot-core/variables.tf modules/iot-core/variables-backup.tf
cp modules/iot-core/outputs.tf modules/iot-core/outputs-backup.tf
```

### Bước 2: Thay Thế Files Với Enhanced Version
```bash
# Replace với enhanced versions
mv modules/iot-core/main-enhanced-security.tf modules/iot-core/main.tf
mv modules/iot-core/variables-enhanced.tf modules/iot-core/variables.tf
mv modules/iot-core/outputs-enhanced.tf modules/iot-core/outputs.tf
```

### Bước 3: Update terraform.tfvars
```hcl
# modules/iot-core/terraform.tfvars
environment = "dev"
project_name = "iot-platform"

# Security enhancements
enable_device_defender = true
enable_enhanced_logging = true
log_retention_days = 30
security_log_retention_days = 90

# Authentication & authorization
auth_failure_threshold = 5
connection_rate_limit = 50
max_message_size_kb = 10

# Device management
device_types = ["temperature_sensor", "humidity_sensor", "motion_sensor"]

# Alerting
alert_email_endpoints = ["admin@company.com", "security@company.com"]

# Compliance
compliance_mode = "soc2"  # hoặc "none", "hipaa", "pci"
data_classification = "confidential"

# Feature flags
feature_flags = {
  enable_ml_anomaly_detection = false
  enable_predictive_maintenance = false
  enable_edge_analytics = false
}
```

## 📋 Triển Khai Từng Phase

### Phase 1: Foundation Security (1-2 tuần)

#### 1.1 Deploy Basic Enhanced Security
```bash
# Plan first để review changes
terraform plan -target=module.iot_core

# Apply foundation components
terraform apply -target=aws_iot_thing_type.sensor
terraform apply -target=aws_iot_thing_group.production_devices
terraform apply -target=aws_iot_thing_group.quarantine_devices
terraform apply -target=aws_dynamodb_table.device_registry
```

#### 1.2 Update IoT Policies
```bash
# Deploy enhanced policies
terraform apply -target=aws_iot_policy.production_device_policy
terraform apply -target=aws_iot_policy.quarantine_policy

# Verify policies are created
aws iot list-policies --region us-east-1
```

#### 1.3 Setup Basic Monitoring
```bash
# Deploy CloudWatch components
terraform apply -target=aws_cloudwatch_log_group.iot_data_logs
terraform apply -target=aws_cloudwatch_log_group.iot_security_logs
terraform apply -target=aws_cloudwatch_log_group.iot_error_logs
terraform apply -target=aws_iot_logging_options.iot_logging
```

### Phase 2: Advanced Security (2-3 tuần)

#### 2.1 Deploy Device Defender
```bash
# Deploy security profiles
terraform apply -target=aws_iot_security_profile.device_security_profile
terraform apply -target=aws_iot_security_profile_target.production_target

# Verify deployment
aws iot describe-security-profile \
  --security-profile-name "iot-platform_security_profile_dev" \
  --region us-east-1
```

#### 2.2 Enhanced Topic Rules
```bash
# Deploy enhanced topic rules
terraform apply -target=aws_iot_topic_rule.validated_data_rule
terraform apply -target=aws_iot_topic_rule.security_events_rule
terraform apply -target=aws_iot_topic_rule.realtime_rule_enhanced
```

#### 2.3 Alerting System
```bash
# Deploy SNS và CloudWatch alarms
terraform apply -target=aws_sns_topic.security_alerts
terraform apply -target=aws_cloudwatch_metric_alarm.high_connection_failures
terraform apply -target=aws_cloudwatch_metric_alarm.unusual_data_volume
terraform apply -target=aws_cloudwatch_metric_alarm.device_defender_violations

# Subscribe to alerts
aws sns subscribe \
  --topic-arn "arn:aws:sns:us-east-1:ACCOUNT:iot-platform_security_alerts_dev" \
  --protocol email \
  --notification-endpoint admin@company.com
```

### Phase 3: Network Security (2-3 tuần)

#### 3.1 VPC Endpoints (Nếu Cần Private Network)
```bash
# Nếu enable private network
terraform apply -var="enable_private_network=true" \
  -var="vpc_id=vpc-xxxxxxxxx" \
  -var="vpc_cidr=10.0.0.0/16" \
  -var="private_subnet_ids=[\"subnet-xxxxxxxx\",\"subnet-yyyyyyyy\"]"
```

### Phase 4: Testing & Validation

#### 4.1 Device Connection Testing
```bash
# Test device connection với new policies
python3 test_scripts/test_device_connection.py \
  --endpoint xxxxxxxxxx-ats.iot.us-east-1.amazonaws.com \
  --cert device-cert.pem \
  --key device-key.pem \
  --ca root-ca.pem
```

#### 4.2 Security Testing
```bash
# Test authentication failures
python3 test_scripts/test_auth_failures.py

# Test message validation
python3 test_scripts/test_message_validation.py

# Test rate limiting
python3 test_scripts/test_rate_limiting.py
```

## 🔧 Migration Scripts

### Script 1: Device Migration
Tạo file `scripts/migrate_devices.py`:

```python
#!/usr/bin/env python3
import boto3
import json
import time
from typing import List, Dict

class DeviceMigration:
    def __init__(self, region: str = 'us-east-1'):
        self.iot = boto3.client('iot', region_name=region)
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        
    def migrate_existing_devices(self, thing_type_name: str, target_group: str):
        """Migrate existing devices to new thing group"""
        try:
            # List existing things
            things = self.iot.list_things(thingTypeName=thing_type_name)
            
            for thing in things.get('things', []):
                thing_name = thing['thingName']
                
                # Add to production group
                self.iot.add_thing_to_thing_group(
                    thingGroupName=target_group,
                    thingName=thing_name
                )
                
                # Register in device registry
                self.register_device_in_dynamodb(thing_name, thing)
                
                print(f"Migrated device: {thing_name}")
                time.sleep(0.1)  # Rate limiting
                
        except Exception as e:
            print(f"Migration error: {e}")
    
    def register_device_in_dynamodb(self, thing_name: str, thing_data: Dict):
        """Register device in new registry table"""
        table = self.dynamodb.Table('iot-platform_device_registry_dev')
        
        try:
            table.put_item(
                Item={
                    'deviceId': thing_name,
                    'status': 'active',
                    'thingType': thing_data.get('thingTypeName', ''),
                    'createdAt': str(int(time.time())),
                    'lastSeen': str(int(time.time())),
                    'attributes': thing_data.get('attributes', {}),
                    'ttl': int(time.time()) + (365 * 24 * 60 * 60)  # 1 year TTL
                }
            )
        except Exception as e:
            print(f"DynamoDB registration error for {thing_name}: {e}")

if __name__ == "__main__":
    migration = DeviceMigration()
    migration.migrate_existing_devices(
        'iot-platform_sensor_dev',
        'iot-platform_production_dev'
    )
```

### Script 2: Certificate Update
Tạo file `scripts/update_certificates.py`:

```python
#!/usr/bin/env python3
import boto3
import json
from datetime import datetime, timedelta

class CertificateManager:
    def __init__(self, region: str = 'us-east-1'):
        self.iot = boto3.client('iot', region_name=region)
    
    def audit_certificates(self):
        """Audit existing certificates"""
        try:
            certificates = self.iot.list_certificates()
            
            for cert in certificates.get('certificates', []):
                cert_id = cert['certificateId']
                cert_details = self.iot.describe_certificate(certificateId=cert_id)
                
                creation_date = cert_details['certificateDescription']['creationDate']
                expiry_date = creation_date + timedelta(days=365)  # Assuming 1 year validity
                days_to_expiry = (expiry_date - datetime.now()).days
                
                print(f"Certificate {cert_id}:")
                print(f"  Status: {cert['status']}")
                print(f"  Days to expiry: {days_to_expiry}")
                print(f"  Creation date: {creation_date}")
                
                if days_to_expiry < 30:
                    print(f"  ⚠️  WARNING: Certificate expires soon!")
                
        except Exception as e:
            print(f"Certificate audit error: {e}")
    
    def update_policy_attachments(self):
        """Update policy attachments for enhanced security"""
        try:
            # List certificates và update policies
            certificates = self.iot.list_certificates()
            
            for cert in certificates.get('certificates', []):
                if cert['status'] == 'ACTIVE':
                    cert_arn = cert['certificateArn']
                    
                    # Detach old policy if exists
                    try:
                        self.iot.detach_policy(
                            policyName='iot-platform_iot_policy_dev',
                            target=cert_arn
                        )
                    except:
                        pass  # Policy might not be attached
                    
                    # Attach new production policy
                    self.iot.attach_policy(
                        policyName='iot-platform_production_policy_dev',
                        target=cert_arn
                    )
                    
                    print(f"Updated policy for certificate: {cert['certificateId']}")
                    
        except Exception as e:
            print(f"Policy update error: {e}")

if __name__ == "__main__":
    cert_manager = CertificateManager()
    cert_manager.audit_certificates()
    cert_manager.update_policy_attachments()
```

## 🔍 Testing & Validation

### Test 1: Security Profile Validation
```bash
# Test script to validate security profiles
cat > test_security_profile.py << 'EOF'
import boto3
import time
import random

def test_auth_failures():
    """Test authentication failure detection"""
    # This would simulate auth failures
    # In practice, this should trigger alarms
    pass

def test_message_size_limits():
    """Test message size validation"""
    # Send oversized message to trigger alarm
    pass

def test_connection_rate_limits():
    """Test connection rate limiting"""
    # Rapid connection attempts
    pass

if __name__ == "__main__":
    test_auth_failures()
    test_message_size_limits()
    test_connection_rate_limits()
EOF

python3 test_security_profile.py
```

### Test 2: Device Defender Monitoring
```bash
# Monitor Device Defender metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/IoTDeviceDefender \
  --metric-name ViolationCount \
  --dimensions Name=SecurityProfileName,Value=iot-platform_security_profile_dev \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## 📊 Monitoring Dashboard

### CloudWatch Dashboard JSON
Tạo file `monitoring/iot_security_dashboard.json`:

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/IoT", "Connect.Success"],
          [".", "Connect.AuthError"],
          [".", "PublishIn.Success"],
          [".", "Subscribe.Success"]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "IoT Core Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/IoTDeviceDefender", "ViolationCount", "SecurityProfileName", "iot-platform_security_profile_dev"]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Security Violations"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/iot/iot-platform/security'\n| fields @timestamp, message\n| filter message like /VIOLATION/\n| sort @timestamp desc\n| limit 20",
        "region": "us-east-1",
        "title": "Recent Security Events"
      }
    }
  ]
}
```

Deploy dashboard:
```bash
aws cloudwatch put-dashboard \
  --dashboard-name "IoT-Security-Dashboard" \
  --dashboard-body file://monitoring/iot_security_dashboard.json
```

## 🚨 Incident Response Runbook

### High Priority Incidents

#### 1. Authentication Failure Spike
```bash
# Investigation steps
aws logs filter-log-events \
  --log-group-name "/aws/iot/iot-platform/security" \
  --filter-pattern "{ $.level = \"ERROR\" && $.event = \"AUTH_FAILURE\" }" \
  --start-time $(date -d '1 hour ago' +%s)000

# Response actions
# 1. Check for brute force attacks
# 2. Review certificate status
# 3. Consider temporary IP blocking
# 4. Notify security team
```

#### 2. Device Defender Violations
```bash
# Check violation details
aws iot list-violation-events \
  --security-profile-name "iot-platform_security_profile_dev" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s)

# Quarantine compromised device
aws iot add-thing-to-thing-group \
  --thing-group-name "iot-platform_quarantine_dev" \
  --thing-name "SUSPICIOUS_DEVICE_ID"
```

## 🔄 Rollback Plan

### Emergency Rollback
```bash
# Quick rollback to previous version
terraform apply -target=module.iot_core \
  -var-file="backup-variables.tfvars" \
  -state="backup-state-$(date +%Y%m%d).json"

# Or restore from backup files
cp modules/iot-core/main-backup.tf modules/iot-core/main.tf
cp modules/iot-core/variables-backup.tf modules/iot-core/variables.tf
cp modules/iot-core/outputs-backup.tf modules/iot-core/outputs.tf

terraform apply -target=module.iot_core
```

### Gradual Rollback
```bash
# Disable specific features one by one
terraform apply -var="enable_device_defender=false"
terraform apply -var="enable_enhanced_logging=false"
```

## 📈 Performance Metrics

### Before vs After Comparison
```bash
# Script to compare performance metrics
cat > performance_comparison.py << 'EOF'
import boto3
from datetime import datetime, timedelta

def get_metrics_comparison():
    cloudwatch = boto3.client('cloudwatch')
    
    # Get metrics for last 24 hours vs previous 24 hours
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=1)
    
    metrics = [
        'Connect.Success',
        'Connect.AuthError',
        'PublishIn.Success',
        'Subscribe.Success'
    ]
    
    for metric in metrics:
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/IoT',
            MetricName=metric,
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Sum', 'Average']
        )
        
        print(f"Metric: {metric}")
        for datapoint in response['Datapoints']:
            print(f"  {datapoint['Timestamp']}: {datapoint['Sum']}")

if __name__ == "__main__":
    get_metrics_comparison()
EOF

python3 performance_comparison.py
```

## 🎯 Success Criteria

### ✅ Phase 1 Complete When:
- [ ] All devices migrated to new thing groups
- [ ] Enhanced policies deployed and attached
- [ ] Basic monitoring operational
- [ ] No connection disruptions during migration

### ✅ Phase 2 Complete When:
- [ ] Device Defender detecting anomalies
- [ ] Security alerts functioning
- [ ] Enhanced topic rules processing messages
- [ ] All alarms configured and tested

### ✅ Phase 3 Complete When:
- [ ] VPC endpoints operational (if enabled)
- [ ] Network traffic flowing through private connections
- [ ] Security groups properly configured

### ✅ Overall Success When:
- [ ] Zero security incidents in first month
- [ ] 99.9% device connectivity maintained
- [ ] All compliance requirements met
- [ ] Team trained on new security features

## 📞 Support Contacts

### Emergency Contacts
- **Primary**: DevOps Team - +84-xxx-xxx-xxx
- **Secondary**: Security Team - security@company.com
- **AWS Support**: Enterprise Support Case

### Escalation Matrix
1. **Level 1**: DevOps Engineer (Response: 15 min)
2. **Level 2**: Senior DevOps/Security (Response: 30 min)
3. **Level 3**: Technical Lead (Response: 1 hour)
4. **Level 4**: AWS Support (Response: 1 hour)

---

## 📚 Additional Resources

- [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
- [Device Defender Documentation](https://docs.aws.amazon.com/iot/latest/developerguide/device-defender.html)
- [IoT Security Best Practices](https://docs.aws.amazon.com/iot/latest/developerguide/security-best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)