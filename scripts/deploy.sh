#!/bin/bash

# ========================================
# SCRIPT TRIỂN KHAI TERRAFORM
# ========================================

set -e  # Dừng script nếu có lỗi

# Colors cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function để in thông báo
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function để kiểm tra prerequisites
check_prerequisites() {
    print_message "Kiểm tra prerequisites..."
    
    # Kiểm tra Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform không được cài đặt. Vui lòng cài đặt Terraform >= 1.0"
        exit 1
    fi
    
    # Kiểm tra AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI không được cài đặt. Vui lòng cài đặt AWS CLI"
        exit 1
    fi
    
    # Kiểm tra AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials không được cấu hình. Vui lòng chạy 'aws configure'"
        exit 1
    fi
    
    # Kiểm tra file terraform.tfvars
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "File terraform.tfvars không tồn tại. Tạo từ terraform.tfvars.example..."
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_success "Đã tạo terraform.tfvars từ example"
        else
            print_error "Không tìm thấy terraform.tfvars.example"
            exit 1
        fi
    fi
    
    print_success "Prerequisites check hoàn thành"
}

# Function để khởi tạo Terraform
init_terraform() {
    print_message "Khởi tạo Terraform..."
    
    # Xóa .terraform nếu tồn tại
    if [ -d ".terraform" ]; then
        print_message "Xóa .terraform directory cũ..."
        rm -rf .terraform
    fi
    
    # Khởi tạo Terraform
    terraform init
    
    print_success "Terraform init hoàn thành"
}

# Function để validate Terraform
validate_terraform() {
    print_message "Validate Terraform configuration..."
    
    terraform validate
    
    print_success "Terraform validation hoàn thành"
}

# Function để plan Terraform
plan_terraform() {
    print_message "Tạo Terraform plan..."
    
    terraform plan -out=tfplan
    
    print_success "Terraform plan hoàn thành"
}

# Function để apply Terraform
apply_terraform() {
    print_message "Apply Terraform configuration..."
    
    if [ -f "tfplan" ]; then
        terraform apply tfplan
    else
        terraform apply -auto-approve
    fi
    
    print_success "Terraform apply hoàn thành"
}

# Function để destroy Terraform (cẩn thận!)
destroy_terraform() {
    print_warning "Bạn có chắc chắn muốn destroy toàn bộ infrastructure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_message "Destroying Terraform infrastructure..."
        terraform destroy -auto-approve
        print_success "Terraform destroy hoàn thành"
    else
        print_message "Hủy bỏ destroy"
    fi
}

# Function để hiển thị outputs
show_outputs() {
    print_message "Hiển thị Terraform outputs..."
    
    terraform output
    
    print_success "Outputs hiển thị hoàn thành"
}

# Function để hiển thị help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init     - Khởi tạo Terraform"
    echo "  plan     - Tạo plan (init + validate + plan)"
    echo "  apply    - Triển khai infrastructure (init + validate + plan + apply)"
    echo "  destroy  - Xóa toàn bộ infrastructure"
    echo "  outputs  - Hiển thị outputs"
    echo "  help     - Hiển thị help này"
    echo ""
    echo "Examples:"
    echo "  $0 init     # Chỉ khởi tạo Terraform"
    echo "  $0 plan     # Tạo plan để xem thay đổi"
    echo "  $0 apply    # Triển khai infrastructure"
    echo "  $0 destroy  # Xóa infrastructure"
}

# Main script
case "${1:-help}" in
    "init")
        check_prerequisites
        init_terraform
        ;;
    "plan")
        check_prerequisites
        init_terraform
        validate_terraform
        plan_terraform
        ;;
    "apply")
        check_prerequisites
        init_terraform
        validate_terraform
        plan_terraform
        apply_terraform
        show_outputs
        ;;
    "destroy")
        check_prerequisites
        destroy_terraform
        ;;
    "outputs")
        show_outputs
        ;;
    "help"|*)
        show_help
        ;;
esac 