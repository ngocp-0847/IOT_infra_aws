# Hướng Dẫn Triển Khai IoT Platform

## 🚀 Triển Khai Infrastructure

### Yêu Cầu Hệ Thống

- Terraform >= 1.0
- AWS CLI configured
- Git

### Bước 1: Cấu Hình AWS

```bash
# Cấu hình AWS credentials
aws configure

# Hoặc sử dụng environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

### Bước 2: Clone Repository

```bash
git clone <repository-url>
cd IOT_infra_aws
```

### Bước 3: Triển Khai Dev Environment

```bash
# Chuyển đến thư mục dev
cd environments/dev

# Khởi tạo Terraform
terraform init

# Plan để xem thay đổi
terraform plan

# Apply để triển khai
terraform apply
```

### Bước 4: Triển Khai Production (Tùy chọn)

```bash
# Chuyển đến thư mục prod
cd environments/prod

# Khởi tạo Terraform
terraform init

# Plan để xem thay đổi
terraform plan

# Apply để triển khai
terraform apply
```

## 🔧 Cấu Hình CI/CD

### GitHub Secrets

Cần cấu hình các secrets sau trong GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS Access Key
- `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key

### Workflow

1. Push code lên branch `main` hoặc `develop`
2. GitHub Actions sẽ tự động:
   - Chạy `terraform plan`
   - Quét lỗ hổng bảo mật với Trivy
   - Apply changes (chỉ trên main branch)

## 📊 Monitoring

### CloudWatch Dashboard

Sau khi triển khai, truy cập CloudWatch Dashboard để monitor:

- Kinesis Stream metrics
- DynamoDB performance
- Lambda function metrics
- Error rates và alarms

### SNS Alerts

Các alerts sẽ được gửi đến SNS topic khi có vấn đề:

- Kinesis stream errors
- Lambda function errors
- DynamoDB system errors

## 🔌 Testing

### Test IoT Device Connection

```bash
# Sử dụng AWS CLI để test IoT Core
aws iot describe-endpoint

# Test publishing message
aws iot-data publish \
  --topic "iot/data" \
  --qos 1 \
  --payload '{"device_id":"test-device","temperature":25.5,"humidity":60.2,"timestamp":"2024-01-01T12:00:00Z"}'
```

### Test API Endpoints

```bash
# Health check
curl https://your-api-gateway-url/health

# Get devices
curl https://your-api-gateway-url/devices

# Get device data
curl https://your-api-gateway-url/devices/test-device
```

## 🧹 Cleanup

### Destroy Infrastructure

```bash
# Dev environment
cd environments/dev
terraform destroy

# Production environment
cd environments/prod
terraform destroy
```

## 📝 Notes

- Infrastructure được tạo với tags để dễ quản lý
- S3 bucket có lifecycle policies để tối ưu chi phí
- VPC endpoints được cấu hình để tăng bảo mật
- Lambda functions có VPC config để truy cập private resources
- CloudWatch alarms được cấu hình cho monitoring

## 🆘 Troubleshooting

### Common Issues

1. **VPC Endpoint Issues**: Kiểm tra security groups và route tables
2. **Lambda Timeout**: Tăng timeout hoặc memory size
3. **Kinesis Shard Issues**: Scale up shard count nếu cần
4. **DynamoDB Throttling**: Kiểm tra capacity units

### Logs

- Lambda logs: CloudWatch Logs
- API Gateway logs: CloudWatch Logs
- Kinesis metrics: CloudWatch Metrics
- DynamoDB metrics: CloudWatch Metrics 