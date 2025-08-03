#!/bin/bash

# =============================================================================
# Get Terraform Resource Information
# =============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if Terraform state exists
check_terraform_state() {
    if [ ! -f "terraform.tfstate" ]; then
        print_error "terraform.tfstate not found in current directory."
        print_info "Please run this script from the directory containing terraform.tfstate"
        return 1
    fi
    return 0
}

# Function to get all Terraform outputs
get_all_outputs() {
    print_info "Getting all Terraform outputs..."
    echo "=================================="
    
    if ! check_terraform_state; then
        exit 1
    fi
    
    # Get all outputs
    local outputs=$(terraform output -json 2>/dev/null)
    
    if [ -z "$outputs" ]; then
        print_error "No Terraform outputs found or terraform not initialized."
        return 1
    fi
    
    # Parse and display outputs
    echo "$outputs" | jq -r 'to_entries[] | "\(.key): \(.value.value)"' 2>/dev/null || {
        print_warning "jq not available, showing raw output:"
        terraform output
    }
}

# Function to get specific resource information
get_resource_info() {
    local resource_type=$1
    
    case $resource_type in
        "api")
            local api_endpoint=$(terraform output -raw api_endpoint 2>/dev/null)
            if [ ! -z "$api_endpoint" ]; then
                print_success "API Gateway Endpoint: $api_endpoint"
            else
                print_warning "API Gateway endpoint not found"
            fi
            ;;
        "iot")
            local iot_endpoint=$(terraform output -raw iot_endpoint 2>/dev/null)
            if [ ! -z "$iot_endpoint" ]; then
                print_success "IoT Core Endpoint: $iot_endpoint"
            else
                print_warning "IoT Core endpoint not found"
            fi
            ;;
        
        "dynamodb")
            local table_name=$(terraform output -raw dynamodb_table_name 2>/dev/null)
            if [ ! -z "$table_name" ]; then
                print_success "DynamoDB Table: $table_name"
            else
                print_warning "DynamoDB table not found"
            fi
            ;;
        "s3")
            local bucket_name=$(terraform output -raw s3_bucket_name 2>/dev/null)
            if [ ! -z "$bucket_name" ]; then
                print_success "S3 Bucket: $bucket_name"
            else
                print_warning "S3 bucket not found"
            fi
            ;;
        "lambda")
            local lambda_info=$(terraform output -json lambda_functions 2>/dev/null)
            if [ ! -z "$lambda_info" ]; then
                print_success "Lambda Functions:"
                echo "$lambda_info" | jq -r 'to_entries[] | "  \(.key): \(.value.name)"' 2>/dev/null || echo "$lambda_info"
            else
                print_warning "Lambda functions not found"
            fi
            ;;
        "vpc")
            local vpc_info=$(terraform output -json vpc_info 2>/dev/null)
            if [ ! -z "$vpc_info" ]; then
                print_success "VPC Information:"
                echo "$vpc_info" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "$vpc_info"
            else
                print_warning "VPC information not found"
            fi
            ;;
        "monitoring")
            local monitoring_info=$(terraform output -json monitoring 2>/dev/null)
            if [ ! -z "$monitoring_info" ]; then
                print_success "Monitoring Information:"
                echo "$monitoring_info" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "$monitoring_info"
            else
                print_warning "Monitoring information not found"
            fi
            ;;
        "certificate")
            local cert_info=$(terraform output -json iot_certificate 2>/dev/null)
            if [ ! -z "$cert_info" ]; then
                print_success "IoT Certificate Information:"
                echo "$cert_info" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "$cert_info"
            else
                print_warning "IoT certificate information not found"
            fi
            ;;
        *)
            print_error "Unknown resource type: $resource_type"
            print_info "Available types: api, iot, dynamodb, s3, lambda, vpc, monitoring, certificate"
            return 1
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -a, --all               Show all resource information"
    echo "  -r, --resource TYPE     Show specific resource information"
    echo "                          Types: api, iot, dynamodb, s3, lambda, vpc, monitoring, certificate"
    echo ""
    echo "Examples:"
    echo "  $0 -a                   # Show all resources"
    echo "  $0 -r api               # Show API Gateway info"
    echo "  $0 -r iot               # Show IoT Core info"
  
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -a|--all)
                get_all_outputs
                exit 0
                ;;
            -r|--resource)
                if [ -z "$2" ]; then
                    print_error "Resource type is required"
                    show_usage
                    exit 1
                fi
                get_resource_info "$2"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Run main function
main "$@" 