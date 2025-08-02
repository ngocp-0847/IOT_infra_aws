# Nền Tảng Phân Tích Dữ Liệu IoT - AWS Infrastructure

## 📋 Tổng Quan

Dự án này triển khai một nền tảng phân tích dữ liệu IoT có khả năng xử lý dữ liệu từ hàng triệu thiết bị cảm biến (nhiệt độ, độ ẩm) với kiến trúc serverless trên AWS.

## 🏗️ Kiến Trúc Hệ Thống

```mermaid
graph TD
    A[IoT Devices] --> B[AWS IoT Core]
    B --> C[Kinesis Data Stream]
    C --> D1[S3 Raw Storage]
    C --> D2[Lambda Stream Processor]
    D2 --> E[DynamoDB Processed Data]
    E --> F[API Gateway]
    F --> G[Lambda Query Handler]
    G --> H[Client Applications]
    
    I[CloudWatch] --> J[Monitoring & Alerts]
    K[Secrets Manager] --> L[Security Management]
    M[VPC] --> N[Network Security]
```

## 🎯 Tính Năng Chính

- **Ingest dữ liệu lớn**: Xử lý hàng triệu message/giây từ thiết bị IoT
- **Lưu trữ dữ liệu thô**: S3 với lifecycle policies cho chi phí tối ưu
- **Xử lý stream real-time**: Lambda functions xử lý dữ liệu theo thời gian thực
- **Query API**: RESTful API để truy vấn dữ liệu đã xử lý
- **Monitoring**: CloudWatch monitoring và alerting

## 🛠️ Công Nghệ Sử Dụng

| Thành phần | Công nghệ | Mục đích |
|------------|-----------|----------|
| **IoT Gateway** | AWS IoT Core | Nhận dữ liệu từ thiết bị IoT |
| **Stream Processing** | Kinesis Data Stream | Thu thập dữ liệu real-time |
| **Raw Storage** | Amazon S3 | Lưu trữ dữ liệu thô |
| **Data Processing** | AWS Lambda | Xử lý stream dữ liệu |
| **Processed Storage** | DynamoDB | Lưu trữ dữ liệu đã xử lý |
| **API Layer** | API Gateway + Lambda | Cung cấp REST API |
| **Monitoring** | CloudWatch | Giám sát và cảnh báo |
| **Security** | IAM, Secrets Manager | Bảo mật và quản lý quyền |

## 🔒 Bảo Mật

- **VPC với Public/Private Subnets**: Tách biệt môi trường
- **IAM Least Privilege**: Chỉ cấp quyền cần thiết
- **Secrets Manager**: Quản lý thông tin nhạy cảm
- **Encryption**: Mã hóa dữ liệu ở rest và in transit
- **Network Security**: Security Groups và NACLs

## 📊 Monitoring & Observability

- **CloudWatch Metrics**: Giám sát hiệu suất hệ thống
- **CloudWatch Logs**: Tập trung hóa logs
- **CloudWatch Alarms**: Cảnh báo khi có vấn đề
- **X-Ray**: Distributed tracing cho API calls

## 🚀 Triển Khai

### Yêu Cầu Hệ Thống

- Terraform >= 1.0
- AWS CLI configured
- Git

### Cấu Hình AWS Region

Dự án được cấu hình để chạy trên **AWS Region us-east-1 (Virginia)** để tối ưu chi phí và hiệu suất.

### Các Bước Triển Khai

1. **Clone repository**:
   ```bash
   git clone <repository-url>
   cd IOT_infra_aws
   ```

2. **Cấu hình AWS credentials**:
   ```bash
   aws configure
   ```

3. **Khởi tạo Terraform**:
   ```bash
   terraform init
   ```

4. **Plan và Apply**:
   ```bash
   terraform plan
   terraform apply
   ```

## 📁 Cấu Trúc Project

```
IOT_infra_aws/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── modules/
│   ├── vpc/
│   ├── iot-core/
│   ├── kinesis/
│   ├── lambda/
│   ├── dynamodb/
│   ├── api-gateway/
│   └── monitoring/
├── environments/
│   ├── dev/
│   └── prod/
└── .github/
    └── workflows/
```

## 💰 Chi Phí Dự Kiến

### 🆓 AWS Free Tier (Tháng 1-12)
| Dịch vụ | Chi phí/tháng | Free Tier Limit |
|---------|---------------|-----------------|
| IoT Core | $0 | 250,000 messages |
| Kinesis | $0 | 2M PUT records |
| S3 | $0 | 5GB storage |
| Lambda | $0 | 1M requests |
| DynamoDB | $0 | 25GB storage |
| API Gateway | $0 | 1M API calls |
| CloudWatch | $0 | 5GB logs |
| **Tổng cộng** | **$0** | **Tiết kiệm $400-1550** |

### 💰 Sau Free Tier (Tháng 13+)
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

> 📊 **ROI**: Tiết kiệm $4,800-18,600 trong năm đầu tiên với Free Tier!

## 🔧 Maintenance

- **Backup**: Tự động backup dữ liệu
- **Updates**: Cập nhật security patches
- **Scaling**: Tự động scale theo tải
- **Monitoring**: 24/7 monitoring

## 📞 Support

Để hỗ trợ kỹ thuật, vui lòng tạo issue trong repository hoặc liên hệ team DevOps. 