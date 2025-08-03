#!/bin/bash

# Script để build Lambda deployment packages
# Sử dụng: ./build.sh

set -e

echo "🚀 Bắt đầu build Lambda functions..."

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Thư mục hiện tại
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_SOURCE_DIR="${SCRIPT_DIR}/lambda"
BUILD_DIR="${SCRIPT_DIR}/build"

# Kiểm tra thư mục lambda source tồn tại
if [ ! -d "$LAMBDA_SOURCE_DIR" ]; then
    echo -e "${RED}❌ Không tìm thấy thư mục lambda source: ${LAMBDA_SOURCE_DIR}${NC}"
    exit 1
fi

# Tạo thư mục build nếu chưa có
mkdir -p "$BUILD_DIR"

# Function để build một lambda function
build_lambda() {
    local func_name=$1
    local source_file="${LAMBDA_SOURCE_DIR}/${func_name}.py"
    local output_zip="${SCRIPT_DIR}/${func_name}.zip"
    local temp_dir="${BUILD_DIR}/${func_name}"
    
    echo -e "${BLUE}📦 Building ${func_name}...${NC}"
    
    # Kiểm tra file source tồn tại
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}❌ Không tìm thấy file: ${source_file}${NC}"
        return 1
    fi
    
    # Tạo thư mục temp
    mkdir -p "$temp_dir"
    
    # Copy file Python
    cp "$source_file" "$temp_dir/"
    
    # Tạo zip file
    cd "$temp_dir"
    zip -r "$output_zip" . -q
    cd "$SCRIPT_DIR"
    
    # Xóa thư mục temp
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✅ Đã tạo: $(basename $output_zip) ($(du -h $output_zip | cut -f1))${NC}"
}

# Build các Lambda functions
echo -e "${YELLOW}📋 Lambda functions sẽ được build:${NC}"
echo "  - query_handler"
echo "  - stream_processor"
echo ""

build_lambda "query_handler"
build_lambda "stream_processor"

# Cleanup build directory
rm -rf "$BUILD_DIR"

echo ""
echo -e "${GREEN}🎉 Build hoàn thành!${NC}"
echo -e "${YELLOW}📁 Các file đã tạo:${NC}"
ls -la "${SCRIPT_DIR}"/*.zip 2>/dev/null || echo "Không có file zip nào được tạo"

echo ""
echo -e "${BLUE}💡 Sử dụng:${NC}"
echo "  terraform plan   # Xem các thay đổi"
echo "  terraform apply  # Deploy các Lambda functions"