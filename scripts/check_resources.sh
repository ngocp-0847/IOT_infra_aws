#!/bin/bash

# =============================================================================
# Script kiểm tra tài nguyên AWS còn lại
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

log_info "Kiểm tra tài nguyên AWS còn lại..."

# Kiểm tra Lambda Functions
echo
log_info "=== Lambda Functions ==="
lambda_functions=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `iot-platform`)].FunctionName' --output text 2>/dev/null || echo "")
if [ ! -z "$lambda_functions" ]; then
    echo "$lambda_functions" | tr '\t' '\n' | while read func; do
        if [ ! -z "$func" ]; then
            log_warning "Lambda Function: $func"
        fi
    done
else
    log_success "Không có Lambda Functions nào"
fi

# Kiểm tra API Gateway
echo
log_info "=== API Gateway ==="
api_gateways=$(aws apigateway get-rest-apis --query 'items[?contains(name, `iot-platform`)].{id:id,name:name}' --output text 2>/dev/null || echo "")
if [ ! -z "$api_gateways" ]; then
    echo "$api_gateways" | tr '\t' '\n' | while read api; do
        if [ ! -z "$api" ]; then
            log_warning "API Gateway: $api"
        fi
    done
else
    log_success "Không có API Gateway nào"
fi

# Kiểm tra IoT Core Rules
echo
log_info "=== IoT Core Rules ==="
iot_rules=$(aws iot list-topic-rules --query 'rules[?contains(ruleName, `iot-platform`)].ruleName' --output text 2>/dev/null || echo "")
if [ ! -z "$iot_rules" ]; then
    echo "$iot_rules" | tr '\t' '\n' | while read rule; do
        if [ ! -z "$rule" ]; then
            log_warning "IoT Rule: $rule"
        fi
    done
else
    log_success "Không có IoT Rules nào"
fi

# Kiểm tra SQS Queues
echo
log_info "=== SQS Queues ==="
sqs_queues=$(aws sqs list-queues --query 'QueueUrls[?contains(@, `iot-platform`)]' --output text 2>/dev/null || echo "")
if [ ! -z "$sqs_queues" ]; then
    echo "$sqs_queues" | tr '\t' '\n' | while read queue; do
        if [ ! -z "$queue" ]; then
            log_warning "SQS Queue: $queue"
        fi
    done
else
    log_success "Không có SQS Queues nào"
fi

# Kiểm tra DynamoDB Tables
echo
log_info "=== DynamoDB Tables ==="
dynamodb_tables=$(aws dynamodb list-tables --query 'TableNames[?contains(@, `iot-platform`)]' --output text 2>/dev/null || echo "")
if [ ! -z "$dynamodb_tables" ]; then
    echo "$dynamodb_tables" | tr '\t' '\n' | while read table; do
        if [ ! -z "$table" ]; then
            log_warning "DynamoDB Table: $table"
        fi
    done
else
    log_success "Không có DynamoDB Tables nào"
fi

# Kiểm tra S3 Buckets
echo
log_info "=== S3 Buckets ==="
s3_buckets=$(aws s3 ls 2>/dev/null | grep iot-platform | awk '{print $3}' || echo "")
if [ ! -z "$s3_buckets" ]; then
    echo "$s3_buckets" | while read bucket; do
        if [ ! -z "$bucket" ]; then
            log_warning "S3 Bucket: $bucket"
        fi
    done
else
    log_success "Không có S3 Buckets nào"
fi

# Kiểm tra VPC Endpoints
echo
log_info "=== VPC Endpoints ==="
vpce_endpoints=$(aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].{id:VpcEndpointId,name:Tags[?Key==`Name`].Value|[0]}' --output text 2>/dev/null || echo "")
if [ ! -z "$vpce_endpoints" ]; then
    echo "$vpce_endpoints" | tr '\t' '\n' | while read endpoint; do
        if [ ! -z "$endpoint" ]; then
            log_warning "VPC Endpoint: $endpoint"
        fi
    done
else
    log_success "Không có VPC Endpoints nào"
fi

# Kiểm tra NAT Gateways
echo
log_info "=== NAT Gateways ==="
nat_gateways=$(aws ec2 describe-nat-gateways --query 'NatGateways[?State!=`deleted`].{id:NatGatewayId,state:State}' --output text 2>/dev/null || echo "")
if [ ! -z "$nat_gateways" ]; then
    echo "$nat_gateways" | tr '\t' '\n' | while read nat; do
        if [ ! -z "$nat" ]; then
            log_warning "NAT Gateway: $nat"
        fi
    done
else
    log_success "Không có NAT Gateways nào"
fi

# Kiểm tra Security Groups
echo
log_info "=== Security Groups ==="
security_groups=$(aws ec2 describe-security-groups --query 'SecurityGroups[?contains(GroupName, `iot-platform`)].{id:GroupId,name:GroupName}' --output text 2>/dev/null || echo "")
if [ ! -z "$security_groups" ]; then
    echo "$security_groups" | tr '\t' '\n' | while read sg; do
        if [ ! -z "$sg" ]; then
            log_warning "Security Group: $sg"
        fi
    done
else
    log_success "Không có Security Groups nào"
fi

# Kiểm tra Subnets
echo
log_info "=== Subnets ==="
subnets=$(aws ec2 describe-subnets --query 'Subnets[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].{id:SubnetId,name:Tags[?Key==`Name`].Value|[0]}' --output text 2>/dev/null || echo "")
if [ ! -z "$subnets" ]; then
    echo "$subnets" | tr '\t' '\n' | while read subnet; do
        if [ ! -z "$subnet" ]; then
            log_warning "Subnet: $subnet"
        fi
    done
else
    log_success "Không có Subnets nào"
fi

# Kiểm tra VPCs
echo
log_info "=== VPCs ==="
vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[?contains(Tags[?Key==`Name`].Value, `iot-platform`)].{id:VpcId,name:Tags[?Key==`Name`].Value|[0]}' --output text 2>/dev/null || echo "")
if [ ! -z "$vpcs" ]; then
    echo "$vpcs" | tr '\t' '\n' | while read vpc; do
        if [ ! -z "$vpc" ]; then
            log_warning "VPC: $vpc"
        fi
    done
else
    log_success "Không có VPCs nào"
fi

echo
log_info "Hoàn thành kiểm tra tài nguyên!" 