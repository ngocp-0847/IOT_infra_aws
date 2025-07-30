# IoT System Test Scripts

## Tổng Quan

Bộ script này được tạo để test toàn bộ hệ thống IoT infrastructure trên AWS. Bao gồm:

1. **`test_iot_system.sh`** - Script test đầy đủ với tất cả chức năng
2. **`quick_test.sh`** - Script test nhanh cho API endpoints
3. **`generate_sample_data.sh`** - Script tạo và push dữ liệu mẫu
4. **`TEST_GUIDE.md`** - Hướng dẫn chi tiết

## Cài Đặt và Cấu Hình

### 1. Yêu Cầu Hệ Thống
```bash
# Cài đặt các công cụ cần thiết
sudo apt update
sudo apt install curl awscli bc jq

# Hoặc trên macOS
brew install curl awscli bc jq
```

### 2. Cấu Hình AWS
```bash
# Cấu hình AWS credentials
aws configure

# Hoặc sử dụng IAM role nếu chạy trên EC2
```

### 3. Làm Script Có Thể Thực Thi
```bash
chmod +x test_iot_system.sh quick_test.sh generate_sample_data.sh
```

## Cách Sử Dụng

### 1. Test Nhanh (Quick Test)
```bash
# Test API endpoints với URL đã biết
./quick_test.sh https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com
```

### 2. Tạo Dữ Liệu Mẫu
```bash
# Tạo dữ liệu với cấu hình mặc định (5 devices, 24 hours)
./generate_sample_data.sh

# Tạo dữ liệu với cấu hình tùy chỉnh
./generate_sample_data.sh -d 10 -t 48 -e your-iot-endpoint.iot.us-east-1.amazonaws.com

# Xem help
./generate_sample_data.sh --help
```

### 3. Test Đầy Đủ Hệ Thống
```bash
# Test tự động (tự tìm endpoints)
./test_iot_system.sh

# Test với tham số tùy chỉnh
./test_iot_system.sh -u https://your-api-url -i your-iot-endpoint -r us-east-1

# Xem help
./test_iot_system.sh --help
```

## Workflow Test Hoàn Chỉnh

### Bước 1: Deploy Infrastructure
```bash
# Deploy với Terraform
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Bước 2: Lấy Thông Tin Endpoints
```bash
# Lấy API Gateway URL
aws apigatewayv2 get-apis --region us-east-1 --query 'Items[?Name==`iot-api`].ApiEndpoint' --output text

# Lấy IoT Endpoint
aws iot describe-endpoint --endpoint-type iot:Data-ATS --region us-east-1 --query 'endpointAddress' --output text
```

### Bước 3: Tạo Dữ Liệu Mẫu
```bash
# Tạo dữ liệu cho 5 devices trong 24 giờ qua
./generate_sample_data.sh -d 5 -t 24
```

### Bước 4: Test API Endpoints
```bash
# Test nhanh
./quick_test.sh https://your-api-url

# Hoặc test đầy đủ
./test_iot_system.sh
```

## Các Test Cases

### API Endpoints
- `GET /health` - Health check
- `GET /devices` - Lấy danh sách devices
- `GET /devices/{device_id}` - Lấy dữ liệu device cụ thể
- `GET /devices/{device_id}?start_time=...&end_time=...` - Lấy dữ liệu theo thời gian

### IoT Data Flow
1. **Publish Data**: Push JSON data lên IoT Core topic `iot/data`
2. **Kinesis Processing**: Data được forward tới Kinesis stream
3. **Lambda Processing**: Stream processor aggregate data theo giờ
4. **DynamoDB Storage**: Lưu data đã được aggregate
5. **API Query**: Query data thông qua API Gateway

## Monitoring và Debug

### CloudWatch Logs
```bash
# Xem Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/iot"

# Xem logs của specific function
aws logs tail /aws/lambda/iot-query-handler-dev --follow
```

### DynamoDB Data
```bash
# Scan data trong DynamoDB
aws dynamodb scan --table-name iot-data-dev --limit 10

# Query data của specific device
aws dynamodb query \
    --table-name iot-data-dev \
    --key-condition-expression "device_id = :device_id" \
    --expression-attribute-values '{":device_id":{"S":"sensor-001"}}'
```

### Kinesis Stream
```bash
# Xem stream info
aws kinesis describe-stream --stream-name iot-data-stream-dev

# Xem shard info
aws kinesis list-shards --stream-name iot-data-stream-dev
```

## Troubleshooting

### Lỗi Thường Gặp

#### 1. "Could not get API URL automatically"
```bash
# Kiểm tra API Gateway
aws apigatewayv2 get-apis --region us-east-1

# Hoặc chỉ định thủ công
./test_iot_system.sh -u https://your-api-url
```

#### 2. "Could not get IoT endpoint automatically"
```bash
# Kiểm tra IoT Core
aws iot describe-endpoint --endpoint-type iot:Data-ATS --region us-east-1

# Hoặc chỉ định thủ công
./test_iot_system.sh -i your-iot-endpoint
```

#### 3. "Health check failed"
```bash
# Kiểm tra Lambda function
aws lambda get-function --function-name iot-query-handler-dev

# Xem CloudWatch logs
aws logs tail /aws/lambda/iot-query-handler-dev
```

#### 4. "Failed to publish data"
```bash
# Kiểm tra IoT Policy
aws iot list-policies

# Kiểm tra Topic Rule
aws iot list-topic-rules
```

### Debug Mode
```bash
# Thêm debug vào script
set -x
./test_iot_system.sh
set +x
```

## Performance Testing

### Load Test
```bash
# Test với nhiều requests
for i in {1..100}; do
    curl -s "https://your-api-url/health" &
done
wait
```

### Stress Test
```bash
# Tạo nhiều devices
./generate_sample_data.sh -d 100 -t 24
```

## Cleanup

### Xóa Dữ Liệu Test
```bash
# Xóa data từ DynamoDB
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

### Destroy Infrastructure
```bash
# Destroy với Terraform
cd environments/dev
terraform destroy
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
      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install -y bc jq
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
        stage('Setup') {
            steps {
                sh 'sudo apt update && sudo apt install -y bc jq'
            }
        }
        stage('Test IoT System') {
            steps {
                sh 'chmod +x test_iot_system.sh'
                sh './test_iot_system.sh'
            }
        }
    }
}
```

## Tài Liệu Tham Khảo

- [TEST_GUIDE.md](./TEST_GUIDE.md) - Hướng dẫn chi tiết
- [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [AWS Kinesis Documentation](https://docs.aws.amazon.com/kinesis/) 