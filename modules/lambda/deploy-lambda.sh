#!/bin/bash

# Script deploy Lambda functions với auto-detection thay đổi
# Sử dụng: ./deploy-lambda.sh [environment]

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Lambda Deployment Script${NC}"
echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
echo ""

# Function để check terraform có sẵn không
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform không được tìm thấy. Vui lòng cài đặt Terraform.${NC}"
        exit 1
    fi
}

# Function để build Lambda functions
build_functions() {
    echo -e "${BLUE}📦 Building Lambda functions...${NC}"
    
    if [ -f "${SCRIPT_DIR}/build.sh" ]; then
        cd "$SCRIPT_DIR"
        ./build.sh
    else
        echo -e "${YELLOW}⚠️  build.sh không tìm thấy, sử dụng quick build...${NC}"
        cd "$SCRIPT_DIR"
        ./quick-build.sh
    fi
    
    echo -e "${GREEN}✅ Build completed${NC}"
}

# Function để check thay đổi
check_changes() {
    echo -e "${BLUE}🔍 Checking for changes...${NC}"
    
    cd "${SCRIPT_DIR}/../../environments/${ENVIRONMENT}"
    
    # Check terraform plan
    if terraform plan -detailed-exitcode -out=tfplan &> /dev/null; then
        echo -e "${GREEN}✅ Không có thay đổi nào cần deploy${NC}"
        rm -f tfplan
        return 1
    else
        exit_code=$?
        if [ $exit_code -eq 2 ]; then
            echo -e "${YELLOW}📋 Có thay đổi cần deploy:${NC}"
            terraform show tfplan
            return 0
        else
            echo -e "${RED}❌ Lỗi khi chạy terraform plan${NC}"
            rm -f tfplan
            exit 1
        fi
    fi
}

# Function để deploy
deploy() {
    echo -e "${BLUE}🚀 Deploying changes...${NC}"
    
    cd "${SCRIPT_DIR}/../../environments/${ENVIRONMENT}"
    
    if terraform apply tfplan; then
        echo -e "${GREEN}🎉 Deploy thành công!${NC}"
        rm -f tfplan
    else
        echo -e "${RED}❌ Deploy thất bại${NC}"
        rm -f tfplan
        exit 1
    fi
}

# Function để show Lambda info
show_lambda_info() {
    echo -e "${BLUE}📋 Lambda Functions Info:${NC}"
    
    cd "${SCRIPT_DIR}/../../environments/${ENVIRONMENT}"
    
    echo "Stream Processor:"
    terraform output lambda_stream_processor_function_name 2>/dev/null || echo "  Chưa deploy"
    
    echo "Query Handler:"
    terraform output lambda_query_handler_function_name 2>/dev/null || echo "  Chưa deploy"
}

# Main execution
main() {
    check_terraform
    
    # Build functions
    build_functions
    
    # Check changes
    if check_changes; then
        echo ""
        read -p "Bạn có muốn deploy các thay đổi này? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            deploy
        else
            echo -e "${YELLOW}🚫 Deploy đã bị hủy${NC}"
            cd "${SCRIPT_DIR}/../../environments/${ENVIRONMENT}"
            rm -f tfplan
        fi
    fi
    
    echo ""
    show_lambda_info
}

# Hiển thị help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "🛠️  Lambda Deploy Script"
    echo ""
    echo "Sử dụng:"
    echo "  ./deploy-lambda.sh [environment]"
    echo ""
    echo "Environments:"
    echo "  dev   - Development environment (default)"
    echo "  prod  - Production environment"
    echo ""
    echo "Options:"
    echo "  -h, --help    Hiển thị help này"
    echo ""
    echo "Examples:"
    echo "  ./deploy-lambda.sh        # Deploy to dev"
    echo "  ./deploy-lambda.sh prod   # Deploy to prod"
    exit 0
fi

# Kiểm tra environment hợp lệ
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${RED}❌ Environment không hợp lệ: ${ENVIRONMENT}${NC}"
    echo "Chỉ hỗ trợ: dev, prod"
    exit 1
fi

# Kiểm tra environment directory tồn tại
if [ ! -d "${SCRIPT_DIR}/../../environments/${ENVIRONMENT}" ]; then
    echo -e "${RED}❌ Environment directory không tồn tại: environments/${ENVIRONMENT}${NC}"
    exit 1
fi

main