# Hướng Dẫn Khắc Phục Lỗi

## Lỗi Kinesis SubscriptionRequiredException

### Lỗi:
```
SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service
```

### Nguyên nhân:
- AWS Kinesis Data Streams chưa được kích hoạt trong region
- Tài khoản AWS chưa được verify
- Region không hỗ trợ Kinesis

### Giải pháp:

#### 1. Chạy script kích hoạt Kinesis:
```bash
./scripts/enable_kinesis_service.sh
```

#### 2. Kích hoạt thủ công qua AWS Console:
1. Đăng nhập vào AWS Console
2. Tìm kiếm "Kinesis Data Streams"
3. Nếu có thông báo subscription, click "Subscribe" hoặc "Enable"
4. Đợi vài phút để service được kích hoạt

#### 3. Đổi sang region khác:
Cập nhật `terraform.tfvars`:
```hcl
aws_region = "us-east-1"  # hoặc us-west-2, eu-west-1
```

#### 4. Verify tài khoản AWS:
- Kiểm tra email verification
- Đảm bảo tài khoản không bị suspend

## Lỗi Lambda Execution Role

### Lỗi:
```
InvalidParameterValueException: The provided execution role does not have permissions to call CreateNetworkInterface on EC2
```

### Nguyên nhân:
Lambda execution role thiếu quyền để tạo network interface trong VPC

### Giải pháp:
Đã được sửa trong `modules/lambda/main.tf` - thêm quyền EC2 cho Lambda role.

## Lỗi VPC Configuration

### Lỗi:
```
Error: creating VPC: operation error EC2: CreateVpc, https response error StatusCode: 400
```

### Giải pháp:
1. Kiểm tra CIDR block không bị conflict
2. Đảm bảo region hỗ trợ VPC
3. Kiểm tra AWS account limits

## Lỗi DynamoDB

### Lỗi:
```
Error: creating DynamoDB table: operation error DynamoDB: CreateTable
```

### Giải pháp:
1. Kiểm tra table name không bị trùng
2. Đảm bảo region hỗ trợ DynamoDB
3. Kiểm tra AWS account limits

## Lỗi S3

### Lỗi:
```
Error: creating S3 bucket: operation error S3: CreateBucket
```

### Giải pháp:
1. Bucket name phải unique globally
2. Kiểm tra bucket naming rules
3. Đảm bảo region hỗ trợ S3

## Lỗi API Gateway

### Lỗi:
```
Error: creating API Gateway: operation error APIGateway: CreateRestApi
```

### Giải pháp:
1. Kiểm tra API name không bị trùng
2. Đảm bảo region hỗ trợ API Gateway
3. Kiểm tra AWS account limits

## Lỗi IoT Core

### Lỗi:
```
Error: creating IoT Thing: operation error IoT: CreateThing
```

### Giải pháp:
1. Kiểm tra thing name không bị trùng
2. Đảm bảo region hỗ trợ IoT Core
3. Kiểm tra AWS account limits

## Lỗi CloudWatch

### Lỗi:
```
Error: creating CloudWatch Log Group: operation error CloudWatchLogs: CreateLogGroup
```

### Giải pháp:
1. Kiểm tra log group name không bị trùng
2. Đảm bảo region hỗ trợ CloudWatch
3. Kiểm tra AWS account limits

## Lỗi IAM

### Lỗi:
```
Error: creating IAM Role: operation error IAM: CreateRole
```

### Giải pháp:
1. Kiểm tra role name không bị trùng
2. Đảm bảo role name tuân thủ naming rules
3. Kiểm tra AWS account limits

## Lỗi Terraform State

### Lỗi:
```
Error: Failed to get existing workspaces: operation error STS: GetCallerIdentity
```

### Giải pháp:
1. Kiểm tra AWS credentials
2. Chạy `aws configure`
3. Kiểm tra AWS CLI version

## Lỗi Free Tier Limits

### Lỗi:
```
Error: creating resource: operation error Service: CreateResource, LimitExceededException
```

### Giải pháp:
1. Kiểm tra Free Tier limits
2. Xóa resources không cần thiết
3. Sử dụng region khác nếu cần

## Các Lệnh Hữu Ích

### Kiểm tra AWS credentials:
```bash
aws sts get-caller-identity
```

### Kiểm tra region:
```bash
aws configure get region
```

### Xóa tất cả resources:
```bash
terraform destroy
```

### Kiểm tra plan:
```bash
terraform plan
```

### Apply changes:
```bash
terraform apply
```

### Xem logs:
```bash
terraform console
```

## Liên Hệ Hỗ Trợ

Nếu vẫn gặp lỗi, vui lòng:
1. Kiểm tra AWS Service Health Dashboard
2. Xem AWS CloudTrail logs
3. Liên hệ AWS Support (nếu có)
4. Tạo issue trên GitHub repository 