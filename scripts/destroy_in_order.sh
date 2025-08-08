#!/bin/bash

# =============================================================================
# Script xóa tài nguyên AWS theo thứ tự phụ thuộc
# =============================================================================

set -e

# Colors cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function để log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Kiểm tra Terraform đã được cài đặt
if ! command -v terraform &> /dev/null; then
    log_error "Terraform không được cài đặt. Vui lòng cài đặt Terraform trước."
    exit 1
fi

# Kiểm tra AWS CLI đã được cài đặt
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI không được cài đặt. Vui lòng cài đặt AWS CLI trước."
    exit 1
fi

# Kiểm tra thư mục hiện tại có file Terraform
if [ ! -f "main.tf" ]; then
    log_error "Không tìm thấy file main.tf. Vui lòng chạy script này từ thư mục gốc của project."
    exit 1
fi

log_info "Bắt đầu quá trình xóa tài nguyên theo thứ tự phụ thuộc..."

# Function để chạy terraform destroy với retry
run_terraform_destroy() {
    local target="$1"
    local description="$2"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        log_info "Thử xóa $description (lần $((retry_count + 1))/$max_retries)..."
        
        if terraform destroy -target="$target" -auto-approve; then
            log_success "Đã xóa $description"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log_warning "Lỗi khi xóa $description. Thử lại sau 10 giây..."
                sleep 10
            else
                log_error "Không thể xóa $description sau $max_retries lần thử"
                return 1
            fi
        fi
    done
}

# Function để kiểm tra tài nguyên còn tồn tại
check_resource_exists() {
    local resource_type="$1"
    local resource_name="$2"
    
    case $resource_type in
        "lambda")
            aws lambda list-functions --query "Functions[?contains(FunctionName, '$resource_name')].FunctionName" --output text | grep -q .
            ;;
        "vpc")
            aws ec2 describe-vpcs --query "Vpcs[?contains(Tags[?Key=='Name'].Value, '$resource_name')].VpcId" --output text | grep -q .
            ;;
        "subnet")
            aws ec2 describe-subnets --query "Subnets[?contains(Tags[?Key=='Name'].Value, '$resource_name')].SubnetId" --output text | grep -q .
            ;;
        "security_group")
            aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, '$resource_name')].GroupId" --output text | grep -q .
            ;;
        "vpc_endpoint")
            aws ec2 describe-vpc-endpoints --query "VpcEndpoints[?contains(Tags[?Key=='Name'].Value, '$resource_name')].VpcEndpointId" --output text | grep -q .
            ;;
        *)
            return 0
            ;;
    esac
}

# Function để xử lý dependencies đặc biệt
handle_special_dependencies() {
    local resource_type="$1"
    
    case $resource_type in
        "security_group")
            log_info "Xử lý dependencies đặc biệt cho Security Groups..."
            
            # Xóa VPC Endpoints sử dụng Security Groups
            if check_resource_exists "vpc_endpoint" "iot-platform"; then
                log_warning "Tìm thấy VPC Endpoints. Xóa trước..."
                aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].VpcEndpointId' --output text | tr '\t' '\n' | while read endpoint; do
                    if [ ! -z "$endpoint" ]; then
                        log_info "Xóa VPC Endpoint: $endpoint"
                        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$endpoint" 2>/dev/null || true
                    fi
                done
                sleep 10
            fi
            
            # Xóa Lambda Functions sử dụng Security Groups
            if check_resource_exists "lambda" "iot-platform"; then
                log_warning "Tìm thấy Lambda Functions. Xóa trước..."
                aws lambda list-functions --query 'Functions[?contains(FunctionName, `iot-platform`)].FunctionName' --output text | tr '\t' '\n' | while read func; do
                    if [ ! -z "$func" ]; then
                        log_info "Xóa Lambda function: $func"
                        aws lambda delete-function --function-name "$func" 2>/dev/null || true
                    fi
                done
                sleep 10
            fi
            ;;
            
        "subnet")
            log_info "Xử lý dependencies đặc biệt cho Subnets..."
            
            # Xóa VPC Endpoints sử dụng Subnets
            if check_resource_exists "vpc_endpoint" "iot-platform"; then
                log_warning "Tìm thấy VPC Endpoints. Xóa trước..."
                aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].VpcEndpointId' --output text | tr '\t' '\n' | while read endpoint; do
                    if [ ! -z "$endpoint" ]; then
                        log_info "Xóa VPC Endpoint: $endpoint"
                        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$endpoint" 2>/dev/null || true
                    fi
                done
                sleep 10
            fi
            
            # Xóa Route Table Associations
            log_info "Xóa Route Table Associations..."
            aws ec2 describe-route-tables --query 'RouteTables[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].RouteTableId' --output text | tr '\t' '\n' | while read rt; do
                if [ ! -z "$rt" ]; then
                    aws ec2 describe-route-tables --route-table-ids "$rt" --query 'RouteTables[0].Associations[?SubnetId!=null].RouteTableAssociationId' --output text | tr '\t' '\n' | while read assoc; do
                        if [ ! -z "$assoc" ]; then
                            log_info "Xóa Route Table Association: $assoc"
                            aws ec2 disassociate-route-table --association-id "$assoc" 2>/dev/null || true
                        fi
                    done
                fi
            done
            sleep 5
            ;;
    esac
}

# Bước 1: Xóa Lambda Functions trước (vì chúng sử dụng VPC)
log_info "Bước 1: Xóa Lambda Functions..."
run_terraform_destroy "module.lambda" "Lambda Functions"

# Bước 2: Xóa API Gateway
log_info "Bước 2: Xóa API Gateway..."
run_terraform_destroy "module.api_gateway" "API Gateway"

# Bước 3: Xóa IoT Core
log_info "Bước 3: Xóa IoT Core..."
run_terraform_destroy "module.iot_core" "IoT Core"

# Bước 4: Xóa Monitoring
log_info "Bước 4: Xóa Monitoring..."
run_terraform_destroy "module.monitoring" "Monitoring"

# Bước 5: Xóa DynamoDB
log_info "Bước 5: Xóa DynamoDB..."
run_terraform_destroy "module.dynamodb" "DynamoDB"

# Bước 6: Xóa SQS
log_info "Bước 6: Xóa SQS..."
run_terraform_destroy "module.sqs" "SQS"

# Bước 7: Xóa S3
log_info "Bước 7: Xóa S3..."
run_terraform_destroy "module.s3_storage" "S3"

# Bước 8: Xóa VPC Endpoints trước khi xóa VPC
log_info "Bước 8: Xóa VPC Endpoints..."
run_terraform_destroy "module.vpc.aws_vpc_endpoint.s3" "VPC Endpoint S3"
run_terraform_destroy "module.vpc.aws_vpc_endpoint.dynamodb" "VPC Endpoint DynamoDB"
run_terraform_destroy "module.vpc.aws_vpc_endpoint.sqs" "VPC Endpoint SQS"

# Bước 9: Xóa Route Table Associations
log_info "Bước 9: Xóa Route Table Associations..."
run_terraform_destroy "module.vpc.aws_route_table_association.public" "Route Table Associations Public"
run_terraform_destroy "module.vpc.aws_route_table_association.private" "Route Table Associations Private"

# Bước 10: Xóa Route Tables
log_info "Bước 10: Xóa Route Tables..."
run_terraform_destroy "module.vpc.aws_route_table.public" "Route Table Public"
run_terraform_destroy "module.vpc.aws_route_table.private" "Route Table Private"

# Bước 11: Xóa Security Groups (với kiểm tra dependencies)
log_info "Bước 11: Xóa Security Groups..."
handle_special_dependencies "security_group"
run_terraform_destroy "module.vpc.aws_security_group.lambda" "Security Groups"

# Bước 12: Xóa NAT Gateways
log_info "Bước 12: Xóa NAT Gateways..."
run_terraform_destroy "module.vpc.aws_nat_gateway.main" "NAT Gateways"

# Bước 13: Xóa EIPs
log_info "Bước 13: Xóa EIPs..."
run_terraform_destroy "module.vpc.aws_eip.nat" "EIPs"

# Bước 14: Xóa Subnets (với kiểm tra dependencies)
log_info "Bước 14: Xóa Subnets..."
handle_special_dependencies "subnet"
run_terraform_destroy "module.vpc.aws_subnet.public" "Subnets Public"
run_terraform_destroy "module.vpc.aws_subnet.private" "Subnets Private"

# Bước 15: Xóa Internet Gateway
log_info "Bước 15: Xóa Internet Gateway..."
run_terraform_destroy "module.vpc.aws_internet_gateway.main" "Internet Gateway"

# Bước 16: Xóa VPC
log_info "Bước 16: Xóa VPC..."
run_terraform_destroy "module.vpc.aws_vpc.main" "VPC"

# Bước 17: Xóa Random String
log_info "Bước 17: Xóa Random String..."
run_terraform_destroy "random_string.suffix" "Random String"

# Bước cuối: Xóa tất cả tài nguyên còn lại
log_info "Bước cuối: Xóa tất cả tài nguyên còn lại..."
terraform destroy -auto-approve
log_success "Đã xóa tất cả tài nguyên"

# Kiểm tra cuối cùng
log_info "Kiểm tra cuối cùng các tài nguyên còn lại..."
echo
log_info "=== Kiểm tra tài nguyên còn lại ==="

# Kiểm tra Lambda Functions
if check_resource_exists "lambda" "iot-platform"; then
    log_warning "Vẫn còn Lambda Functions!"
else
    log_success "Không còn Lambda Functions"
fi

# Kiểm tra VPC
if check_resource_exists "vpc" "iot-platform"; then
    log_warning "Vẫn còn VPC!"
else
    log_success "Không còn VPC"
fi

# Kiểm tra Security Groups
if check_resource_exists "security_group" "iot-platform"; then
    log_warning "Vẫn còn Security Groups!"
else
    log_success "Không còn Security Groups"
fi

# Kiểm tra Subnets
if check_resource_exists "subnet" "iot-platform"; then
    log_warning "Vẫn còn Subnets!"
else
    log_success "Không còn Subnets"
fi

echo
log_success "Hoàn thành xóa tài nguyên theo thứ tự phụ thuộc!"
log_info "Tất cả tài nguyên AWS đã được xóa thành công."

# Gợi ý sử dụng script force destroy nếu còn tài nguyên
if check_resource_exists "lambda" "iot-platform" || check_resource_exists "vpc" "iot-platform" || check_resource_exists "security_group" "iot-platform" || check_resource_exists "subnet" "iot-platform"; then
    echo
    log_warning "Vẫn còn một số tài nguyên chưa được xóa."
    log_info "Bạn có thể sử dụng script force destroy để xóa khẩn cấp:"
    log_info "./scripts/force_destroy.sh --force"
fi 