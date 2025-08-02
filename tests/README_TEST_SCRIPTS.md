# Hướng Dẫn Sử Dụng Scripts Test IoT Platform

## Tổng Quan

Thư mục `tests/` chứa các script để test và tương tác với IoT Platform được triển khai bằng Terraform.

## Các Scripts Có Sẵn

### 1. `generate_sample_data.sh`

Script chính để tạo và gửi dữ liệu mẫu đến IoT Core.

#### Tính Năng:
- Tự động lấy thông tin resource từ Terraform outputs
- Tạo dữ liệu sensor với nhiều loại (temperature, humidity, pressure, location, battery, signal)
- Hỗ trợ nhiều thiết bị và khoảng thời gian
- Kiểm tra AWS credentials và tools cần thiết
- Báo cáo chi tiết về kết quả gửi dữ liệu

#### Cách Sử Dụng:

```bash
# Chạy với cấu hình mặc định
./tests/generate_sample_data.sh

# Chỉ định IoT endpoint thủ công
./tests/generate_sample_data.sh -e abc123.iot.us-east-2.amazonaws.com

# Tùy chỉnh số lượng thiết bị và thời gian
./tests/generate_sample_data.sh -d 10 -t 48

# Chỉ định project và environment
./tests/generate_sample_data.sh -p my-iot-project -env prod

# Gửi dữ liệu với interval khác
./tests/generate_sample_data.sh -i 60
```

#### Options:
- `-h, --help`: Hiển thị help
- `-e, --endpoint ENDPOINT`: Chỉ định IoT endpoint thủ công
- `-d, --devices COUNT`: Số lượng thiết bị (mặc định: 5)
- `-t, --hours HOURS`: Số giờ tạo dữ liệu (mặc định: 24)
- `-r, --region REGION`: AWS region (mặc định: us-east-2)
- `-i, --interval SECONDS`: Interval giữa các lần gửi (mặc định: 300)
- `-p, --project NAME`: Tên project (mặc định: iot-data-platform)
- `-env, --environment ENV`: Environment (mặc định: dev)
- `--topic TOPIC`: IoT topic (mặc định: iot/data)

### 2. `get_terraform_info.sh`

Script để lấy thông tin về các resource AWS từ Terraform outputs.

#### Cách Sử Dụng:

```bash
# Hiển thị tất cả resource information
./tests/get_terraform_info.sh -a

# Hiển thị thông tin API Gateway
./tests/get_terraform_info.sh -r api

# Hiển thị thông tin IoT Core
./tests/get_terraform_info.sh -r iot

# Hiển thị thông tin Kinesis
./tests/get_terraform_info.sh -r kinesis

# Hiển thị thông tin DynamoDB
./tests/get_terraform_info.sh -r dynamodb

# Hiển thị thông tin S3
./tests/get_terraform_info.sh -r s3

# Hiển thị thông tin Lambda
./tests/get_terraform_info.sh -r lambda

# Hiển thị thông tin VPC
./tests/get_terraform_info.sh -r vpc

# Hiển thị thông tin Monitoring
./tests/get_terraform_info.sh -r monitoring

# Hiển thị thông tin IoT Certificate
./tests/get_terraform_info.sh -r certificate
```

## Yêu Cầu Hệ Thống

### Tools Cần Thiết:
- `aws-cli`: AWS Command Line Interface
- `jq`: JSON processor (optional, để format output đẹp hơn)
- `bc`: Basic calculator (optional, để tính toán floating point)

### Cài Đặt Tools:

#### Trên macOS:
```bash
# Cài đặt aws-cli
brew install awscli

# Cài đặt jq
brew install jq

# Cài đặt bc (thường có sẵn)
```

#### Trên Ubuntu/Debian:
```bash
# Cài đặt aws-cli
sudo apt update
sudo apt install awscli jq bc
```

#### Trên CentOS/RHEL:
```bash
# Cài đặt aws-cli
sudo yum install awscli jq bc
```

### Cấu Hình AWS:

```bash
# Cấu hình AWS credentials
aws configure

# Hoặc sử dụng AWS_PROFILE
export AWS_PROFILE=your-profile-name
```

## Workflow Test

### 1. Triển Khai Infrastructure

```bash
# Khởi tạo Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

### 2. Lấy Thông Tin Resource

```bash
# Chuyển đến thư mục gốc của project
cd /path/to/iot-platform

# Lấy thông tin tất cả resources
./tests/get_terraform_info.sh -a
```

### 3. Tạo Dữ Liệu Test

```bash
# Tạo dữ liệu mẫu
./tests/generate_sample_data.sh

# Hoặc với tùy chỉnh
./tests/generate_sample_data.sh -d 10 -t 48 -i 60
```

### 4. Test API Endpoints

Sau khi có dữ liệu, bạn có thể test các API endpoints:

```bash
# Lấy API endpoint
API_URL=$(terraform output -raw api_endpoint)

# Test health check
curl $API_URL/health

# Lấy danh sách devices
curl $API_URL/devices

# Lấy dữ liệu của device cụ thể
curl $API_URL/devices/sensor-001

# Lấy dữ liệu theo thời gian
curl $API_URL/devices/sensor-001/data?hours=24
```

## Cấu Trúc Dữ Liệu

Script `generate_sample_data.sh` tạo dữ liệu với format JSON như sau:

```json
{
    "device_id": "sensor-001",
    "timestamp": "2024-01-15T10:30:00Z",
    "temperature": 25.5,
    "humidity": 65.2,
    "pressure": 1013.2,
    "location": {
        "latitude": 10.123456,
        "longitude": 106.123456
    },
    "battery_level": 85.5,
    "signal_strength": 92.3
}
```

## Troubleshooting

### Lỗi Thường Gặp:

1. **AWS credentials not configured**
   ```bash
   aws configure
   ```

2. **IoT endpoint not found**
   ```bash
   # Kiểm tra Terraform state
   terraform output iot_endpoint
   
   # Hoặc lấy endpoint thủ công
   aws iot describe-endpoint --endpoint-type iot:Data-ATS --region us-east-2
   ```

3. **Permission denied**
   ```bash
   # Cấp quyền execute cho scripts
   chmod +x tests/*.sh
   ```

4. **Terraform state not found**
   ```bash
   # Đảm bảo chạy script từ thư mục chứa terraform.tfstate
   ls terraform.tfstate
   ```

### Debug Mode:

Để debug, bạn có thể thêm `set -x` vào đầu script:

```bash
#!/bin/bash
set -x  # Enable debug mode
```

## Monitoring và Logs

### CloudWatch Logs:
- Lambda functions logs: `/aws/lambda/iot-platform-dev-*`
- API Gateway logs: `/aws/apigateway/iot-data-api`

### CloudWatch Metrics:
- Kinesis: `PutRecord.Success`, `PutRecord.ThrottledRecords`
- DynamoDB: `ConsumedReadCapacityUnits`, `ConsumedWriteCapacityUnits`
- Lambda: `Invocations`, `Duration`, `Errors`

## Best Practices

1. **Test với ít dữ liệu trước**: Bắt đầu với `-d 1 -t 1`
2. **Monitor costs**: Sử dụng CloudWatch để theo dõi chi phí
3. **Clean up**: Xóa resources khi không cần thiết
4. **Security**: Không commit AWS credentials vào code
5. **Backup**: Backup Terraform state files

## Liên Hệ

Nếu gặp vấn đề, hãy kiểm tra:
1. AWS credentials và permissions
2. Terraform state file
3. Network connectivity
4. Resource limits và quotas 