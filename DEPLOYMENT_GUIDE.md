# 🚀 Hướng Dẫn Triển Khai IoT Infrastructure

## 📋 Tổng Quan

Hướng dẫn này sẽ giúp bạn triển khai nền tảng phân tích dữ liệu IoT trên AWS sử dụng Terraform.

## 🛠️ Yêu Cầu Hệ Thống

### Bắt Buộc
- **Terraform** >= 1.0
- **AWS CLI** >= 2.0
- **Git**

### Khuyến Nghị
- **Docker** (để chạy tests)
- **jq** (để xử lý JSON outputs)

## 🔧 Cài Đặt Prerequisites

### 1. Cài Đặt Terraform
```bash
# macOS
brew install terraform

# Ubuntu/Debian
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Windows
# Tải từ https://www.terraform.io/downloads.html
```

### 2. Cài Đặt AWS CLI
```bash
# macOS
brew install awscli

# Ubuntu/Debian
sudo apt-get install awscli

# Windows
# Tải từ https://aws.amazon.com/cli/
```

### 3. Cấu Hình AWS Credentials
```bash
aws configure
# Nhập AWS Access Key ID
# Nhập AWS Secret Access Key
# Nhập Default region (ap-southeast-1)
# Nhập Default output format (json)
```

## 🚀 Triển Khai Nhanh

### Phương Pháp 1: Sử Dụng Script Tự Động (Khuyến Nghị)

```bash
# Clone repository
git clone <repository-url>
cd IOT_infra_aws

# Triển khai toàn bộ infrastructure
./scripts/deploy.sh apply
```

### Phương Pháp 2: Triển Khai Thủ Công

```bash
# 1. Khởi tạo Terraform
terraform init

# 2. Tạo plan để xem thay đổi
terraform plan

# 3. Triển khai infrastructure
terraform apply
```

## 📁 Cấu Hình Biến Môi Trường

### 1. File terraform.tfvars
File này đã được tạo sẵn với cấu hình mặc định cho môi trường dev:

```hcl
aws_region   = "ap-southeast-1"
project_name = "iot-data-platform"
environment  = "dev"

# VPC Configuration
vpc_cidr              = "10.0.0.0/16"
availability_zones    = ["ap-southeast-1a", "ap-southeast-1b"]
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]

# Kinesis Configuration
kinesis_stream_name = "iot-sensor-stream"
kinesis_shard_count = 1

# DynamoDB Configuration
dynamodb_table_name = "iot-processed-data"

# S3 Configuration
s3_bucket_name = "iot-raw-data-2024"

# Lambda Configuration
lambda_runtime     = "python3.11"
lambda_timeout     = 300
lambda_memory_size = 512

# API Gateway Configuration
api_gateway_name = "iot-data-api"

# Tags
tags = {
  Project     = "iot-data-platform"
  Environment = "dev"
  Owner       = "devops-team"
  ManagedBy   = "terraform"
}
```

### 2. Tùy Chỉnh Cấu Hình

#### Cho Môi Trường Production
```bash
# Copy file example
cp terraform.tfvars.example terraform.tfvars.prod

# Chỉnh sửa các giá trị
sed -i 's/environment = "dev"/environment = "prod"/' terraform.tfvars.prod
sed -i 's/kinesis_shard_count = 1/kinesis_shard_count = 4/' terraform.tfvars.prod
sed -i 's/lambda_memory_size = 512/lambda_memory_size = 1024/' terraform.tfvars.prod

# Sử dụng file cấu hình production
terraform apply -var-file=terraform.tfvars.prod
```

#### Cho Môi Trường Staging
```bash
# Tạo file staging
cp terraform.tfvars.example terraform.tfvars.staging

# Chỉnh sửa
sed -i 's/environment = "dev"/environment = "staging"/' terraform.tfvars.staging
sed -i 's/kinesis_shard_count = 1/kinesis_shard_count = 2/' terraform.tfvars.staging

# Triển khai staging
terraform apply -var-file=terraform.tfvars.staging
```

## 🔍 Kiểm Tra Triển Khai

### 1. Kiểm Tra Resources Đã Tạo
```bash
# Xem danh sách resources
terraform state list

# Xem thông tin chi tiết resource
terraform state show aws_s3_bucket.raw_data
terraform state show aws_dynamodb_table.processed_data
```

### 2. Kiểm Tra Outputs
```bash
# Xem tất cả outputs
terraform output

# Xem output cụ thể
terraform output api_gateway_url
terraform output s3_bucket_name
```

### 3. Kiểm Tra AWS Console
- **S3**: Kiểm tra bucket `iot-raw-data-2024`
- **DynamoDB**: Kiểm tra table `iot-processed-data`
- **Lambda**: Kiểm tra functions đã tạo
- **API Gateway**: Kiểm tra API endpoints
- **CloudWatch**: Kiểm tra logs và metrics

## 🧪 Testing

### 1. Chạy Tests Tự Động
```bash
# Chạy tất cả tests
./tests/test_iot_system.sh

# Chạy test cụ thể
./tests/generate_sample_data.sh
```

### 2. Test Manual
```bash
# Test API Gateway
curl -X GET "https://your-api-gateway-url/dev/sensors"

# Test IoT Core (cần AWS CLI)
aws iot-data publish --topic "sensor/data" --payload '{"temperature": 25.5, "humidity": 60}'
```

## 🗑️ Xóa Infrastructure

### Phương Pháp 1: Sử Dụng Script
```bash
./scripts/deploy.sh destroy
```

### Phương Pháp 2: Thủ Công
```bash
terraform destroy
```

⚠️ **Cảnh Báo**: Lệnh này sẽ xóa toàn bộ infrastructure và dữ liệu!

## 📊 Monitoring

### 1. CloudWatch Metrics
- **IoT Core**: Số lượng messages, errors
- **Kinesis**: Throughput, errors
- **Lambda**: Duration, errors, throttles
- **DynamoDB**: Read/Write capacity
- **API Gateway**: Request count, latency

### 2. CloudWatch Logs
```bash
# Xem logs Lambda
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/iot"

# Xem logs cụ thể
aws logs tail /aws/lambda/iot-stream-processor --follow
```

### 3. CloudWatch Alarms
- CPU utilization > 80%
- Memory utilization > 80%
- Error rate > 5%
- API Gateway 4xx/5xx errors

## 🔧 Troubleshooting

### Lỗi Thường Gặp

#### 1. "Access Denied"
```bash
# Kiểm tra AWS credentials
aws sts get-caller-identity

# Kiểm tra IAM permissions
aws iam get-user
```

#### 2. "Bucket Already Exists"
```bash
# Đổi tên bucket trong terraform.tfvars
s3_bucket_name = "iot-raw-data-2024-unique"
```

#### 3. "VPC CIDR Conflict"
```bash
# Đổi CIDR trong terraform.tfvars
vpc_cidr = "10.1.0.0/16"
```

#### 4. "Lambda Timeout"
```bash
# Tăng timeout trong terraform.tfvars
lambda_timeout = 600
```

### Debug Commands
```bash
# Validate configuration
terraform validate

# Format code
terraform fmt

# Show plan
terraform plan -detailed-exitcode

# Show state
terraform show
```

## 💰 Cost Optimization

### 1. Free Tier Optimization
- Sử dụng 1 Kinesis shard
- Lambda memory 512MB
- DynamoDB PAY_PER_REQUEST
- S3 lifecycle policies

### 2. Production Optimization
- Auto-scaling Kinesis shards
- Lambda provisioned concurrency
- DynamoDB auto-scaling
- S3 intelligent tiering

### 3. Cost Monitoring
```bash
# Xem cost breakdown
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

## 📞 Support

### Liên Hệ
- **GitHub Issues**: Tạo issue trong repository
- **Email**: devops@company.com
- **Slack**: #iot-infrastructure

### Tài Liệu Tham Khảo
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS IoT Core](https://docs.aws.amazon.com/iot/)
- [AWS Kinesis](https://docs.aws.amazon.com/kinesis/)
- [AWS Lambda](https://docs.aws.amazon.com/lambda/)

---

**Lưu ý**: Đảm bảo backup dữ liệu quan trọng trước khi destroy infrastructure! 