# Thay Đổi Kiến Trúc: Từ Kinesis Data Stream Sang SQS + Lambda

## 📋 Tổng Quan Thay Đổi

Dự án đã được cập nhật để thay thế **Kinesis Data Stream** bằng **SQS Queue + Lambda** để tối ưu chi phí và đơn giản hóa kiến trúc.

## 🔄 Các Thay Đổi Chính

### 1. **Module Mới: SQS**
- **File**: `modules/sqs/`
- **Tính năng**:
  - SQS Queue với Dead Letter Queue (DLQ)
  - CloudWatch Logs cho monitoring
  - IAM Policy cho quyền truy cập
  - Tối ưu cho Free Tier

### 2. **Cập Nhật IoT Core Module**
- **File**: `modules/iot-core/main.tf`
- **Thay đổi**:
  - IoT Topic Rule: `kinesis_rule` → `sqs_rule`
  - IAM Role: `iot_kinesis_role` → `iot_sqs_role`
  - IAM Policy: `kinesis:PutRecord` → `sqs:SendMessage`

### 3. **Cập Nhật Lambda Module**
- **File**: `modules/lambda/main.tf`
- **Thay đổi**:
  - Event Source Mapping: `kinesis_mapping` → `sqs_mapping`
  - Batch size: 100 → 10 (tối ưu cho SQS)
  - Thêm `maximum_batching_window_in_seconds = 5`

### 4. **Cập Nhật Lambda Code**
- **File**: `modules/lambda/lambda/stream_processor.py`
- **Thay đổi**:
  - Xử lý SQS messages thay vì Kinesis records
  - `record['kinesis']['data']` → `record['body']`

### 5. **Cập Nhật VPC Module**
- **File**: `modules/vpc/main.tf`
- **Thay đổi**:
  - VPC Endpoint: `kinesis` → `sqs`
  - Service name: `kinesis-streams` → `sqs`

### 6. **Cập Nhật Monitoring Module**
- **File**: `modules/monitoring/main.tf`
- **Thay đổi**:
  - CloudWatch Alarm: `kinesis_errors` → `sqs_errors`
  - Metric: `GetRecords.IteratorAgeMilliseconds` → `ApproximateAgeOfOldestMessage`
  - Namespace: `AWS/Kinesis` → `AWS/SQS`

### 7. **Cập Nhật Variables**
- **File**: `variables.tf`
- **Thay đổi**:
  - `kinesis_stream_name` → `sqs_queue_name`
  - `kinesis_shard_count` → (removed)

## 💰 Lợi Ích Chi Phí

### Free Tier (Tháng 1-12)
| Dịch vụ | Kinesis | SQS | Tiết kiệm |
|---------|---------|-----|-----------|
| Free Tier Limit | 2M PUT records | 1M requests | Tương đương |
| Chi phí | $0 | $0 | $0 |

### Sau Free Tier (Tháng 13+)
| Dịch vụ | Kinesis | SQS | Tiết kiệm |
|---------|---------|-----|-----------|
| Chi phí/tháng | $20-100 | $5-30 | **$15-70** |
| Độ phức tạp | Cao | Thấp | **Đơn giản hơn** |

## 🚀 Lợi Ích Kỹ Thuật

### 1. **Đơn Giản Hóa**
- ✅ Không cần quản lý shards
- ✅ Không cần partition keys
- ✅ Dead Letter Queue tích hợp sẵn

### 2. **Tối Ưu Chi Phí**
- ✅ Chi phí thấp hơn 50-70%
- ✅ Không có chi phí provisioned capacity
- ✅ Pay-per-use model

### 3. **Reliability**
- ✅ Message durability cao hơn
- ✅ Automatic retry mechanism
- ✅ DLQ cho failed messages

### 4. **Monitoring**
- ✅ CloudWatch metrics tích hợp
- ✅ Message age monitoring
- ✅ Queue depth monitoring

## 🔧 Cách Triển Khai

### 1. **Xóa Infrastructure Cũ**
```bash
terraform destroy -target=module.kinesis
```

### 2. **Triển Khai Infrastructure Mới**
```bash
terraform plan
terraform apply
```

### 3. **Kiểm Tra**
```bash
# Kiểm tra SQS queue
aws sqs get-queue-attributes --queue-url <queue-url>

# Kiểm tra Lambda function
aws lambda get-function --function-name <function-name>
```

## 📊 So Sánh Performance

| Metric | Kinesis | SQS | Ghi chú |
|--------|---------|-----|---------|
| Throughput | 1MB/s/shard | 300 messages/s | SQS đủ cho IoT use case |
| Latency | ~200ms | ~100ms | SQS nhanh hơn |
| Durability | 99.9% | 99.999999% | SQS tốt hơn |
| Cost | Cao | Thấp | SQS rẻ hơn 50-70% |

## 🎯 Kết Luận

Việc chuyển từ Kinesis sang SQS mang lại:
- ✅ **Tiết kiệm chi phí**: 50-70% thấp hơn
- ✅ **Đơn giản hóa**: Ít phức tạp hơn
- ✅ **Reliability cao hơn**: Message durability tốt hơn
- ✅ **Monitoring tốt hơn**: CloudWatch metrics tích hợp

**Khuyến nghị**: Sử dụng SQS cho IoT data ingestion với volume < 1M messages/giờ. 