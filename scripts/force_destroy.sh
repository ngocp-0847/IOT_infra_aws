#!/bin/bash

# =============================================================================
# Script xóa khẩn cấp cho tài nguyên AWS bị stuck
# =============================================================================

set -e

# Colors cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Kiểm tra tham số
if [ "$1" != "--force" ]; then
    log_error "Script này sẽ xóa tất cả tài nguyên AWS. Sử dụng --force để xác nhận."
    log_warning "Cú pháp: $0 --force"
    exit 1
fi

log_warning "BẠN SẼ XÓA TẤT CẢ TÀI NGUYÊN AWS!"
log_warning "Điều này không thể hoàn tác!"
echo
read -p "Bạn có chắc chắn muốn tiếp tục? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Đã hủy bỏ."
    exit 0
fi

log_info "Bắt đầu xóa khẩn cấp..."

# Bước 1: Xóa tất cả Lambda Functions
log_info "Bước 1: Xóa Lambda Functions..."
aws lambda list-functions --query 'Functions[?contains(FunctionName, `iot-platform`)].FunctionName' --output text | tr '\t' '\n' | while read function_name; do
    if [ ! -z "$function_name" ]; then
        log_info "Xóa Lambda function: $function_name"
        aws lambda delete-function --function-name "$function_name" 2>/dev/null || true
    fi
done

# Bước 2: Xóa API Gateway
log_info "Bước 2: Xóa API Gateway..."
aws apigateway get-rest-apis --query 'items[?contains(name, `iot-platform`)].id' --output text | tr '\t' '\n' | while read api_id; do
    if [ ! -z "$api_id" ]; then
        log_info "Xóa API Gateway: $api_id"
        aws apigateway delete-rest-api --rest-api-id "$api_id" 2>/dev/null || true
    fi
done

# Bước 3: Xóa IoT Core Rules
log_info "Bước 3: Xóa IoT Core Rules..."
aws iot list-topic-rules --query 'rules[?contains(ruleName, `iot-platform`)].ruleName' --output text | tr '\t' '\n' | while read rule_name; do
    if [ ! -z "$rule_name" ]; then
        log_info "Xóa IoT Rule: $rule_name"
        aws iot delete-topic-rule --rule-name "$rule_name" 2>/dev/null || true
    fi
done

# Bước 4: Xóa SQS Queues
log_info "Bước 4: Xóa SQS Queues..."
aws sqs list-queues --query 'QueueUrls[?contains(@, `iot-platform`)]' --output text | tr '\t' '\n' | while read queue_url; do
    if [ ! -z "$queue_url" ]; then
        log_info "Xóa SQS Queue: $queue_url"
        aws sqs delete-queue --queue-url "$queue_url" 2>/dev/null || true
    fi
done

# Bước 5: Xóa DynamoDB Tables
log_info "Bước 5: Xóa DynamoDB Tables..."
aws dynamodb list-tables --query 'TableNames[?contains(@, `iot-platform`)]' --output text | tr '\t' '\n' | while read table_name; do
    if [ ! -z "$table_name" ]; then
        log_info "Xóa DynamoDB Table: $table_name"
        aws dynamodb delete-table --table-name "$table_name" 2>/dev/null || true
    fi
done

# Bước 6: Xóa S3 Buckets
log_info "Bước 6: Xóa S3 Buckets..."
aws s3 ls | grep iot-platform | awk '{print $3}' | while read bucket_name; do
    if [ ! -z "$bucket_name" ]; then
        log_info "Xóa S3 Bucket: $bucket_name"
        aws s3 rb s3://"$bucket_name" --force 2>/dev/null || true
    fi
done

# Bước 7: Xóa VPC Endpoints
log_info "Bước 7: Xóa VPC Endpoints..."
aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].VpcEndpointId' --output text | tr '\t' '\n' | while read endpoint_id; do
    if [ ! -z "$endpoint_id" ]; then
        log_info "Xóa VPC Endpoint: $endpoint_id"
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$endpoint_id" 2>/dev/null || true
    fi
done

# Bước 8: Xóa NAT Gateways
log_info "Bước 8: Xóa NAT Gateways..."
aws ec2 describe-nat-gateways --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text | tr '\t' '\n' | while read nat_id; do
    if [ ! -z "$nat_id" ]; then
        log_info "Xóa NAT Gateway: $nat_id"
        aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" 2>/dev/null || true
    fi
done

# Bước 9: Xóa EIPs
log_info "Bước 9: Xóa EIPs..."
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text | tr '\t' '\n' | while read eip_id; do
    if [ ! -z "$eip_id" ]; then
        log_info "Xóa EIP: $eip_id"
        aws ec2 release-address --allocation-id "$eip_id" 2>/dev/null || true
    fi
done

# Bước 10: Xóa Security Groups
log_info "Bước 10: Xóa Security Groups..."
aws ec2 describe-security-groups --query 'SecurityGroups[?contains(GroupName, `iot-platform`)].GroupId' --output text | tr '\t' '\n' | while read sg_id; do
    if [ ! -z "$sg_id" ]; then
        log_info "Xóa Security Group: $sg_id"
        aws ec2 delete-security-group --group-id "$sg_id" 2>/dev/null || true
    fi
done

# Bước 11: Xóa Subnets
log_info "Bước 11: Xóa Subnets..."
aws ec2 describe-subnets --query 'Subnets[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].SubnetId' --output text | tr '\t' '\n' | while read subnet_id; do
    if [ ! -z "$subnet_id" ]; then
        log_info "Xóa Subnet: $subnet_id"
        aws ec2 delete-subnet --subnet-id "$subnet_id" 2>/dev/null || true
    fi
done

# Bước 12: Xóa Route Tables
log_info "Bước 12: Xóa Route Tables..."
aws ec2 describe-route-tables --query 'RouteTables[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].RouteTableId' --output text | tr '\t' '\n' | while read rt_id; do
    if [ ! -z "$rt_id" ]; then
        log_info "Xóa Route Table: $rt_id"
        aws ec2 delete-route-table --route-table-id "$rt_id" 2>/dev/null || true
    fi
done

# Bước 13: Xóa Internet Gateways
log_info "Bước 13: Xóa Internet Gateways..."
aws ec2 describe-internet-gateways --query 'InternetGateways[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].InternetGatewayId' --output text | tr '\t' '\n' | while read igw_id; do
    if [ ! -z "$igw_id" ]; then
        log_info "Xóa Internet Gateway: $igw_id"
        aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id $(aws ec2 describe-internet-gateways --internet-gateway-ids "$igw_id" --query 'InternetGateways[0].Attachments[0].VpcId' --output text) 2>/dev/null || true
        aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" 2>/dev/null || true
    fi
done

# Bước 14: Xóa VPCs
log_info "Bước 14: Xóa VPCs..."
aws ec2 describe-vpcs --query 'Vpcs[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].VpcId' --output text | tr '\t' '\n' | while read vpc_id; do
    if [ ! -z "$vpc_id" ]; then
        log_info "Xóa VPC: $vpc_id"
        aws ec2 delete-vpc --vpc-id "$vpc_id" 2>/dev/null || true
    fi
done

log_success "Hoàn thành xóa khẩn cấp!"
log_info "Tất cả tài nguyên AWS đã được xóa thành công." 