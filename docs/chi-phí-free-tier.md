# 📊 Phân Tích Chi Phí AWS Free Tier cho IoT Infrastructure

## 🎯 Tổng Quan

Dự án IoT Infrastructure hiện tại có thể được tối ưu hóa để sử dụng AWS Free Tier, giúp giảm chi phí xuống gần 0$ trong 12 tháng đầu tiên.

## 💰 Chi Phí Hiện Tại vs Free Tier

### 📈 Chi Phí Hiện Tại (ước tính/tháng)
| Dịch vụ | Chi phí hiện tại | Lý do |
|---------|------------------|-------|
| IoT Core | $50-200 | Message routing và device management |
| Kinesis | $100-500 | Data streaming với ON_DEMAND mode |
| S3 | $20-100 | Raw data storage với lifecycle policies |
| Lambda | $50-200 | Stream processing và query handling |
| DynamoDB | $100-300 | Processed data storage |
| API Gateway | $50-150 | REST API endpoints |
| CloudWatch | $30-100 | Monitoring và logging |
| **Tổng cộng** | **$400-1550** | |

### 🆓 AWS Free Tier Limits

| Dịch vụ | Free Tier Limit | Thời gian |
|---------|----------------|-----------|
| **IoT Core** | 250,000 messages/tháng | 12 tháng |
| **Kinesis** | 2 million PUT records/tháng | 12 tháng |
| **S3** | 5GB storage + 20,000 GET requests | 12 tháng |
| **Lambda** | 1M requests + 400,000 GB-seconds | 12 tháng |
| **DynamoDB** | 25GB storage + 25 WCU/25 RCU | 12 tháng |
| **API Gateway** | 1M API calls/tháng | 12 tháng |
| **CloudWatch** | 5GB data ingestion + 10 custom metrics | 12 tháng |

## 🎯 Tối Ưu Hóa cho Free Tier

### 1. **IoT Core** - Tiết kiệm $50-200/tháng
```hcl
# Tối ưu: Giảm số lượng messages
# Free Tier: 250,000 messages/tháng
# Khuyến nghị: Batch messages, compress data
```

### 2. **Kinesis** - Tiết kiệm $100-500/tháng
```hcl
# Hiện tại: ON_DEMAND mode (đắt)
# Tối ưu: Chuyển sang PROVISIONED mode với 1 shard
# Free Tier: 2M PUT records/tháng
```

### 3. **S3** - Tiết kiệm $20-100/tháng
```hcl
# Free Tier: 5GB storage
# Tối ưu: 
# - Compress data trước khi upload
# - Sử dụng S3 Intelligent Tiering
# - Lifecycle policies aggressive hơn
```

### 4. **Lambda** - Tiết kiệm $50-200/tháng
```hcl
# Free Tier: 1M requests + 400K GB-seconds
# Tối ưu:
# - Giảm memory allocation
# - Optimize code execution time
# - Batch processing
```

### 5. **DynamoDB** - Tiết kiệm $100-300/tháng
```hcl
# Free Tier: 25GB + 25 WCU/25 RCU
# Tối ưu:
# - Sử dụng PAY_PER_REQUEST mode
# - Compress data
# - TTL để auto-delete old data
```

### 6. **API Gateway** - Tiết kiệm $50-150/tháng
```hcl
# Free Tier: 1M API calls/tháng
# Tối ưu:
# - Implement caching
# - Rate limiting
# - Response compression
```

### 7. **CloudWatch** - Tiết kiệm $30-100/tháng
```hcl
# Free Tier: 5GB logs + 10 metrics
# Tối ưu:
# - Giảm log retention
# - Filter logs trước khi gửi
# - Sử dụng CloudWatch Insights
```

## 🛠️ Các Thay Đổi Cần Thiết

### 1. **Kinesis Stream Configuration**
```hcl
# Thay đổi từ ON_DEMAND sang PROVISIONED
resource "aws_kinesis_stream" "iot_stream" {
  name             = var.stream_name
  retention_period = 24
  shard_count      = 1  # Tối thiểu cho Free Tier

  tags = merge(var.tags, {
    Name = "${var.project_name}-kinesis-stream-${var.environment}"
  })
}
```

### 2. **Lambda Memory Optimization**
```hcl
# Giảm memory size để tiết kiệm GB-seconds
resource "aws_lambda_function" "stream_processor" {
  memory_size = 128  # Giảm từ 512MB xuống 128MB
  timeout     = 30   # Giảm timeout
}
```

### 3. **S3 Lifecycle Policies**
```hcl
# Aggressive lifecycle để giảm storage cost
resource "aws_s3_bucket_lifecycle_configuration" "raw_data" {
  rule {
    id     = "aggressive_transition"
    status = "Enabled"

    transition {
      days          = 7    # Giảm từ 30 xuống 7
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30   # Giảm từ 90 xuống 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90  # Xóa sau 90 ngày thay vì 365
    }
  }
}
```

### 4. **DynamoDB TTL**
```hcl
# Thêm TTL để auto-delete old data
resource "aws_dynamodb_table" "processed_data" {
  # ... existing config ...
  
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
```

## 📊 Chi Phí Dự Kiến Sau Tối Ưu

### 🆓 Tháng 1-12 (Free Tier)
| Dịch vụ | Chi phí/tháng | Tiết kiệm |
|---------|---------------|-----------|
| IoT Core | $0 | $50-200 |
| Kinesis | $0 | $100-500 |
| S3 | $0 | $20-100 |
| Lambda | $0 | $50-200 |
| DynamoDB | $0 | $100-300 |
| API Gateway | $0 | $50-150 |
| CloudWatch | $0 | $30-100 |
| **Tổng cộng** | **$0** | **$400-1550** |

### 💰 Tháng 13+ (Sau Free Tier)
| Dịch vụ | Chi phí/tháng | Tối ưu |
|---------|---------------|--------|
| IoT Core | $10-50 | Batch processing |
| Kinesis | $20-100 | 1 shard provisioned |
| S3 | $5-20 | Aggressive lifecycle |
| Lambda | $10-50 | Memory optimization |
| DynamoDB | $20-80 | TTL + compression |
| API Gateway | $10-30 | Caching |
| CloudWatch | $5-20 | Log filtering |
| **Tổng cộng** | **$80-350** | **Giảm 80-90%** |

## 🎯 Khuyến Nghị Triển Khai

### 1. **Giai Đoạn 1: Free Tier Setup**
- Triển khai với cấu hình tối ưu cho Free Tier
- Monitor usage để không vượt quá limits
- Implement cost alerts

### 2. **Giai Đoạn 2: Production Scaling**
- Sau 12 tháng, evaluate usage patterns
- Scale up theo nhu cầu thực tế
- Implement auto-scaling policies

### 3. **Giai Đoạn 3: Cost Optimization**
- Sử dụng Reserved Instances cho DynamoDB
- Implement data archiving strategies
- Optimize Lambda cold starts

## 🚨 Monitoring & Alerts

### CloudWatch Alarms
```hcl
# Free Tier Usage Alerts
resource "aws_cloudwatch_metric_alarm" "free_tier_usage" {
  alarm_name          = "free-tier-usage-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeTierUsage"
  namespace           = "AWS/Usage"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Free Tier usage approaching limit"
}
```

### Cost Budget
```hcl
# AWS Budgets để track chi phí
resource "aws_budgets_budget" "cost" {
  name              = "iot-infrastructure-budget"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00:00"
  time_unit         = "MONTHLY"
}
```

## 📈 Kết Luận

Với các tối ưu hóa trên, dự án IoT Infrastructure có thể:

✅ **Tháng 1-12**: Chi phí $0 (Free Tier)  
✅ **Tháng 13+**: Chi phí $80-350/tháng (giảm 80-90%)  
✅ **ROI**: Tiết kiệm $4,800-18,600 trong năm đầu tiên  

**Khuyến nghị**: Triển khai ngay với cấu hình Free Tier để test và validate hệ thống trước khi scale up. 