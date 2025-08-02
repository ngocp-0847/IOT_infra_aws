#!/bin/bash

# Script để kích hoạt Kinesis Data Streams service
# Giải quyết lỗi SubscriptionRequiredException

echo "🔧 Đang kích hoạt Kinesis Data Streams service..."

# Kiểm tra AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI chưa được cài đặt. Vui lòng cài đặt AWS CLI trước."
    exit 1
fi

# Kiểm tra AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials chưa được cấu hình. Vui lòng chạy 'aws configure' trước."
    exit 1
fi

# Lấy region hiện tại
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    echo "❌ AWS region chưa được cấu hình. Vui lòng chạy 'aws configure' và set region."
    exit 1
fi

echo "📍 Region hiện tại: $REGION"

# Kiểm tra xem Kinesis có được hỗ trợ trong region này không
echo "🔍 Kiểm tra Kinesis support trong region $REGION..."

# Thử tạo một stream test để kích hoạt service
echo "🚀 Đang tạo test stream để kích hoạt service..."

aws kinesis create-stream \
    --stream-name "test-activation-stream" \
    --shard-count 1 \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Kinesis service đã được kích hoạt thành công!"
    
    # Xóa test stream
    echo "🧹 Đang xóa test stream..."
    aws kinesis delete-stream \
        --stream-name "test-activation-stream" \
        --region $REGION
    
    echo "✅ Hoàn tất! Bây giờ bạn có thể chạy lại terraform apply."
else
    echo "❌ Không thể kích hoạt Kinesis service. Có thể do:"
    echo "   - Tài khoản AWS chưa được verify"
    echo "   - Region không hỗ trợ Kinesis"
    echo "   - Vấn đề với AWS credentials"
    echo ""
    echo "💡 Thử các giải pháp sau:"
    echo "   1. Verify tài khoản AWS email"
    echo "   2. Đổi sang region khác (us-east-1, us-west-2, eu-west-1)"
    echo "   3. Kiểm tra lại AWS credentials"
fi 