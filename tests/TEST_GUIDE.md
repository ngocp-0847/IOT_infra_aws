# Hướng Dẫn Test Hệ Thống IoT

## Tổng Quan

File `test_iot_system.sh` là một script bash để test toàn bộ hệ thống IoT infrastructure trên AWS. Script này sẽ:

1. **Health Check**: Kiểm tra API Gateway có hoạt động không
2. **Push Sample Data**: Đẩy dữ liệu mẫu lên IoT Core
3. **Query Data**: Test các API endpoints để lấy dữ liệu

## Yêu Cầu Hệ Thống

### Công Cụ Cần Thiết
- `curl`: Để gọi API endpoints
- `aws-cli`: Để tương tác với AWS services
- `bc`: Để tính toán số thập phân (optional)

### Cài Đặt AWS CLI
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install awscli

# CentOS/RHEL
sudo yum install awscli

# macOS
brew install awscli
```

### Cấu Hình AWS Credentials
```bash
aws configure
```

## Cách Sử Dụng

### 1. Chạy Script Tự Động
```bash
chmod +x test_iot_system.sh
./test_iot_system.sh
```

Script sẽ tự động:
- Tìm API Gateway URL từ AWS
- Tìm IoT Endpoint từ AWS
- Chạy tất cả các test

### 2. Chạy Với Tham Số Tùy Chỉnh
```bash
# Chỉ định API URL
./test_iot_system.sh -u https://abc123.execute-api.us-east-1.amazonaws.com

# Chỉ định IoT Endpoint
./test_iot_system.sh -i abc123.iot.us-east-1.amazonaws.com

# Chỉ định AWS Region
./test_iot_system.sh -r us-west-2

# Kết hợp nhiều tham số
./test_iot_system.sh -u https://abc123.execute-api.us-east-1.amazonaws.com -i abc123.iot.us-east-1.amazonaws.com -r us-east-1
```

### 3. Xem Help
```bash
./test_iot_system.sh --help
```

## Các Test Cases

### Test 1: Health Check
- **Endpoint**: `GET /health`
- **Mục đích**: Kiểm tra API Gateway có hoạt động không
- **Expected**: Status 200 với response `{"status": "healthy", "timestamp": "..."}`

### Test 2: Push Sample Data
- **Thao tác**: Đẩy dữ liệu mẫu lên IoT Core
- **Dữ liệu**: 5 devices × 24 hours = 120 records
- **Format**: JSON với device_id, timestamp, temperature, humidity

### Test 3: Get Devices
- **Endpoint**: `GET /devices`
- **Mục đích**: Lấy danh sách tất cả devices
- **Expected**: Status 200 với danh sách devices

### Test 4: Get Device Data
- **Endpoint**: `GET /devices/{device_id}`
- **Mục đích**: Lấy dữ liệu của một device cụ thể
- **Expected**: Status 200 với dữ liệu aggregated

### Test 5: Get Device Data với Time Range
- **Endpoint**: `GET /devices/{device_id}?start_time=...&end_time=...`
- **Mục đích**: Lấy dữ liệu trong khoảng thời gian
- **Expected**: Status 200 với dữ liệu được filter

## Cấu Trúc Dữ Liệu Mẫu

### Input Data (IoT Core)
```json
{
    "device_id": "sensor-001",
    "timestamp": "2024-01-15T10:30:00Z",
    "temperature": 25.5,
    "humidity": 65.2
}
```

### Output Data (API Response)
```json
{
    "device_id": "sensor-001",
    "data": [
        {
            "device_id": "sensor-001",
            "timestamp_hour": "2024-01-15T10:00:00",
            "avg_temperature": 25.5,
            "avg_humidity": 65.2,
            "min_temperature": 25.5,
            "max_temperature": 25.5,
            "min_humidity": 65.2,
            "max_humidity": 65.2,
            "count": 1,
            "last_updated": "2024-01-15T10:30:00"
        }
    ],
    "count": 1
}
```

## Troubleshooting

### Lỗi Thường Gặp

#### 1. "Could not get API URL automatically"
**Nguyên nhân**: API Gateway chưa được deploy hoặc tên không đúng
**Giải pháp**: 
- Kiểm tra Terraform deployment
- Chỉ định API URL thủ công: `./test_iot_system.sh -u YOUR_API_URL`

#### 2. "Could not get IoT endpoint automatically"
**Nguyên nhân**: IoT Core chưa được setup
**Giải pháp**:
- Kiểm tra IoT Core configuration
- Chỉ định IoT endpoint thủ công: `./test_iot_system.sh -i YOUR_IOT_ENDPOINT`

#### 3. "Health check failed"
**Nguyên nhân**: Lambda function chưa được deploy hoặc có lỗi
**Giải pháp**:
- Kiểm tra CloudWatch logs của Lambda
- Kiểm tra IAM permissions

#### 4. "Failed to publish data"
**Nguyên nhân**: IoT Core permissions hoặc topic rule chưa setup
**Giải pháp**:
- Kiểm tra IoT Policy
- Kiểm tra Topic Rule configuration

### Debug Mode
Để debug chi tiết hơn, bạn có thể thêm `set -x` vào đầu script:

```bash
#!/bin/bash
set -x  # Add this line for debug
```

## Monitoring

### CloudWatch Logs
- **Lambda Logs**: `/aws/lambda/iot-query-handler-dev`
- **IoT Logs**: CloudWatch IoT logs (nếu enabled)

### DynamoDB
- Kiểm tra bảng `iot-data-dev` để xem dữ liệu được lưu

### Kinesis
- Kiểm tra stream `iot-data-stream-dev` để xem data flow

## Performance Testing

### Load Test
Để test với nhiều dữ liệu hơn:

```bash
# Tạo script load test riêng
for i in {1..100}; do
    ./test_iot_system.sh -u YOUR_API_URL -i YOUR_IOT_ENDPOINT &
done
wait
```

### Stress Test
```bash
# Test với 1000 devices
for device in {1..1000}; do
    aws iot-data publish \
        --endpoint-url "https://$IOT_ENDPOINT" \
        --topic "iot/data" \
        --payload "{\"device_id\":\"sensor-$device\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"temperature\":25,\"humidity\":60}" \
        --region us-east-1
done
```

## Cleanup

Để xóa dữ liệu test:

```bash
# Xóa dữ liệu từ DynamoDB
aws dynamodb scan \
    --table-name iot-data-dev \
    --attributes-to-get device_id timestamp_hour \
    --query 'Items[?device_id.S =~ "sensor-.*"]' \
    --output json | \
jq -r '.Items[] | "\(.device_id.S) \(.timestamp_hour.S)"' | \
while read device_id timestamp; do
    aws dynamodb delete-item \
        --table-name iot-data-dev \
        --key "{\"device_id\":{\"S\":\"$device_id\"},\"timestamp_hour\":{\"S\":\"$timestamp\"}}"
done
```

## Tích Hợp CI/CD

### GitHub Actions
```yaml
name: IoT System Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Run IoT Tests
        run: |
          chmod +x test_iot_system.sh
          ./test_iot_system.sh
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Test IoT System') {
            steps {
                sh 'chmod +x test_iot_system.sh'
                sh './test_iot_system.sh'
            }
        }
    }
}
``` 