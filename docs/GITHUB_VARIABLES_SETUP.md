# Hướng Dẫn Cấu Hình GitHub Environment Variables

## Tổng Quan
File này hướng dẫn cấu hình các biến môi trường trong GitHub repository để workflow CI/CD hoạt động đúng.

## Biến Bắt Buộc (Required Variables)

Vào **GitHub Repository > Settings > Environments > dev > Environment Variables** và thêm:

### 1. PROJECT_NAME
- **Value**: `iot_data_platform`
- **Mô tả**: Tên project, phải trùng với giá trị trong `terraform.tfvars`

### 2. ENVIRONMENT  
- **Value**: `dev`
- **Mô tả**: Môi trường triển khai, phải trùng với giá trị trong `terraform.tfvars`

## Biến Tùy Chọn (Optional Variables)

### 3. AWS_REGION
- **Value**: `us-east-1` (hoặc region bạn muốn sử dụng)
- **Default**: `us-east-1` nếu không set
- **Mô tả**: AWS region để triển khai

### 4. AWS_ACCOUNT_ID
- **Value**: `206218410076` (hoặc AWS Account ID của bạn)
- **Default**: `206218410076` nếu không set
- **Mô tả**: AWS Account ID để tạo ARN role

## Cách Cấu Hình

1. Truy cập repository GitHub
2. Vào **Settings** tab
3. Chọn **Environments** từ sidebar
4. Chọn environment **dev** (tạo mới nếu chưa có)
5. Trong phần **Environment variables**, click **Add variable**
6. Thêm từng biến theo danh sách trên

## Kiểm Tra Cấu Hình

Sau khi cấu hình, chạy workflow để kiểm tra. Workflow sẽ hiển thị:
- ✅ Biến đã được cấu hình đúng
- ❌ Biến bị thiếu (cần thêm)
- ⚠️ Biến sử dụng giá trị mặc định

## Lưu Ý

- Giá trị `PROJECT_NAME` và `ENVIRONMENT` phải trùng khớp với `terraform.tfvars`
- Nếu thay đổi AWS Account hoặc region, cần cập nhật các biến tương ứng
- Role ARN được tạo theo format: `arn:aws:iam::{AWS_ACCOUNT_ID}:role/{PROJECT_NAME}-github-actions-{ENVIRONMENT}`
