# Hướng Dẫn Xóa Tài Nguyên AWS

## Tổng Quan

Khi xóa tài nguyên AWS, đôi khi bạn sẽ gặp lỗi `DependencyViolation` vì các tài nguyên có phụ thuộc lẫn nhau. Để giải quyết vấn đề này, chúng tôi đã tạo 2 script:

1. **`scripts/destroy_in_order.sh`** - Xóa theo thứ tự phụ thuộc với Terraform
2. **`scripts/force_destroy.sh`** - Xóa khẩn cấp bằng AWS CLI

## Cách Sử Dụng

### 1. Script Xóa Theo Thứ Tự (Khuyến Nghị)

```bash
# Cấp quyền thực thi
chmod +x scripts/destroy_in_order.sh

# Chạy script
./scripts/destroy_in_order.sh
```

**Ưu điểm:**
- An toàn, sử dụng Terraform
- Xóa theo đúng thứ tự phụ thuộc
- Có thể rollback nếu cần

**Thứ tự xóa:**
1. Lambda Functions
2. API Gateway
3. IoT Core
4. Monitoring
5. DynamoDB
6. SQS
7. S3
8. VPC Endpoints
9. Route Table Associations
10. Route Tables
11. Security Groups
12. NAT Gateways
13. EIPs
14. Subnets
15. Internet Gateway
16. VPC
17. Random String

### 2. Script Xóa Khẩn Cấp

```bash
# Cấp quyền thực thi
chmod +x scripts/force_destroy.sh

# Chạy script với xác nhận
./scripts/force_destroy.sh --force
```

**Khi nào sử dụng:**
- Khi Terraform bị stuck và không thể xóa
- Khi cần xóa nhanh trong trường hợp khẩn cấp
- Khi có lỗi DependencyViolation nghiêm trọng

**Lưu ý:**
- Script này sẽ xóa TẤT CẢ tài nguyên có tag `iot-platform`
- Không thể hoàn tác
- Cần xác nhận bằng `--force` và `yes`

## Xử Lý Lỗi Thường Gặp

### 1. Lỗi DependencyViolation

```bash
Error: deleting EC2 Subnet: The subnet has dependencies and cannot be deleted.
```

**Giải pháp:**
- Sử dụng script `destroy_in_order.sh`
- Hoặc xóa thủ công theo thứ tự:
  1. Lambda Functions (sử dụng VPC)
  2. VPC Endpoints
  3. Route Table Associations
  4. Subnets

### 2. Lỗi Security Group

```bash
Error: deleting Security Group: resource has a dependent object
```

**Giải pháp:**
- Xóa Lambda Functions trước
- Xóa VPC Endpoints
- Sau đó xóa Security Groups

### 3. Lỗi NAT Gateway

```bash
Error: deleting NAT Gateway: The NAT Gateway is still in use
```

**Giải pháp:**
- Xóa Route Tables sử dụng NAT Gateway
- Xóa Subnets
- Sau đó xóa NAT Gateway

## Các Lệnh Thủ Công

Nếu script không hoạt động, bạn có thể chạy các lệnh thủ công:

### Xóa Lambda Functions
```bash
terraform destroy -target=module.lambda -auto-approve
```

### Xóa VPC Endpoints
```bash
terraform destroy -target=module.vpc.aws_vpc_endpoint.s3 -auto-approve
terraform destroy -target=module.vpc.aws_vpc_endpoint.dynamodb -auto-approve
terraform destroy -target=module.vpc.aws_vpc_endpoint.sqs -auto-approve
```

### Xóa Route Table Associations
```bash
terraform destroy -target=module.vpc.aws_route_table_association.public -auto-approve
terraform destroy -target=module.vpc.aws_route_table_association.private -auto-approve
```

### Xóa Subnets
```bash
terraform destroy -target=module.vpc.aws_subnet.public -auto-approve
terraform destroy -target=module.vpc.aws_subnet.private -auto-approve
```

## Kiểm Tra Tài Nguyên Còn Lại

```bash
# Kiểm tra Lambda Functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `iot-platform`)].FunctionName'

# Kiểm tra VPC
aws ec2 describe-vpcs --query 'Vpcs[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].VpcId'

# Kiểm tra S3 Buckets
aws s3 ls | grep iot-platform

# Kiểm tra DynamoDB Tables
aws dynamodb list-tables --query 'TableNames[?contains(@, `iot-platform`)]'
```

## Lưu Ý Quan Trọng

1. **Backup dữ liệu** trước khi xóa
2. **Kiểm tra dependencies** trước khi xóa
3. **Sử dụng script theo thứ tự** để tránh lỗi
4. **Chỉ sử dụng force destroy** khi thực sự cần thiết
5. **Kiểm tra lại** sau khi xóa để đảm bảo không còn tài nguyên nào

## Troubleshooting

### Script không chạy được
```bash
# Kiểm tra quyền
ls -la scripts/

# Cấp quyền thực thi
chmod +x scripts/*.sh
```

### AWS CLI không hoạt động
```bash
# Kiểm tra cấu hình AWS
aws configure list

# Cấu hình lại nếu cần
aws configure
```

### Terraform không tìm thấy
```bash
# Kiểm tra Terraform
terraform version

# Cài đặt Terraform nếu cần
# (Tham khảo: https://www.terraform.io/downloads)
``` 