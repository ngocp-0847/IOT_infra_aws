#!/bin/bash

# =============================================================================
# IoT System Test Script
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL=""
AWS_REGION="us-east-1"
IOT_ENDPOINT=""

# Function to print colored output
print_status() {
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

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# Check required tools
check_command "curl"
check_command "aws"

# Function to get API Gateway URL
get_api_url() {
    print_status "Getting API Gateway URL..."
    
    # Try to get from AWS CLI
    API_URL=$(aws apigatewayv2 get-apis --region $AWS_REGION --query 'Items[?Name==`iot-api`].ApiEndpoint' --output text 2>/dev/null)
    
    if [ -z "$API_URL" ]; then
        print_warning "Could not get API URL automatically. Please set API_BASE_URL manually."
        print_status "You can find the API URL in AWS Console or Terraform output"
        return 1
    fi
    
    API_BASE_URL="https://$API_URL"
    print_success "API URL: $API_BASE_URL"
    return 0
}

# Function to get IoT Endpoint
get_iot_endpoint() {
    print_status "Getting IoT Endpoint..."
    
    IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --region $AWS_REGION --query 'endpointAddress' --output text 2>/dev/null)
    
    if [ -z "$IOT_ENDPOINT" ]; then
        print_warning "Could not get IoT endpoint automatically. Please set IOT_ENDPOINT manually."
        return 1
    fi
    
    print_success "IoT Endpoint: $IOT_ENDPOINT"
    return 0
}

# Function to test health check
test_health_check() {
    print_status "Testing health check endpoint..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Health check passed"
        echo "Response: $body"
    else
        print_error "Health check failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to generate sample data
generate_sample_data() {
    local device_id=$1
    local timestamp=$2
    
    cat << EOF
{
    "device_id": "$device_id",
    "timestamp": "$timestamp",
    "temperature": $(echo "scale=1; $RANDOM % 50 + 10" | bc),
    "humidity": $(echo "scale=1; $RANDOM % 40 + 30" | bc)
}
EOF
}

# Function to push data to IoT Core
push_iot_data() {
    print_status "Pushing sample data to IoT Core..."
    
    if [ -z "$IOT_ENDPOINT" ]; then
        print_error "IOT_ENDPOINT is not set"
        return 1
    fi
    
    # Generate sample data for multiple devices
    devices=("sensor-001" "sensor-002" "sensor-003" "sensor-004" "sensor-005")
    
    for device in "${devices[@]}"; do
        # Generate data for the last 24 hours
        for i in {0..23}; do
            timestamp=$(date -u -d "$i hours ago" +"%Y-%m-%dT%H:%M:%SZ")
            data=$(generate_sample_data "$device" "$timestamp")
            
            print_status "Publishing data for $device at $timestamp"
            
            # Use AWS CLI to publish to IoT topic
            aws iot-data publish \
                --endpoint-url "https://$IOT_ENDPOINT" \
                --topic "iot/data" \
                --payload "$data" \
                --region $AWS_REGION
            
            if [ $? -eq 0 ]; then
                print_success "Data published for $device"
            else
                print_error "Failed to publish data for $device"
            fi
            
            # Small delay to avoid overwhelming the system
            sleep 0.5
        done
    done
}

# Function to test get devices endpoint
test_get_devices() {
    print_status "Testing get devices endpoint..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/devices")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Get devices endpoint working"
        echo "Response: $body"
    else
        print_error "Get devices failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to test get device data endpoint
test_get_device_data() {
    local device_id=$1
    
    print_status "Testing get device data endpoint for $device_id..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/devices/$device_id")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Get device data endpoint working for $device_id"
        echo "Response: $body"
    else
        print_error "Get device data failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to test device data with time range
test_get_device_data_with_time() {
    local device_id=$1
    local start_time=$2
    local end_time=$3
    
    print_status "Testing get device data with time range for $device_id..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    url="$API_BASE_URL/devices/$device_id?start_time=$start_time&end_time=$end_time"
    response=$(curl -s -w "\n%{http_code}" "$url")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Get device data with time range working for $device_id"
        echo "Response: $body"
    else
        print_error "Get device data with time range failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Main test function
run_tests() {
    print_status "Starting IoT System Tests..."
    echo "=================================="
    
    # Get endpoints
    get_api_url
    get_iot_endpoint
    
    # Test 1: Health check
    echo ""
    print_status "Test 1: Health Check"
    test_health_check
    
    # Test 2: Push sample data
    echo ""
    print_status "Test 2: Push Sample Data"
    push_iot_data
    
    # Wait for data processing
    echo ""
    print_status "Waiting for data processing (30 seconds)..."
    sleep 30
    
    # Test 3: Get devices
    echo ""
    print_status "Test 3: Get Devices"
    test_get_devices
    
    # Test 4: Get device data
    echo ""
    print_status "Test 4: Get Device Data"
    test_get_device_data "sensor-001"
    
    # Test 5: Get device data with time range
    echo ""
    print_status "Test 5: Get Device Data with Time Range"
    start_time=$(date -u -d "12 hours ago" +"%Y-%m-%dT%H:%M:%SZ")
    end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    test_get_device_data_with_time "sensor-001" "$start_time" "$end_time"
    
    echo ""
    print_success "All tests completed!"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -u, --api-url URL   Set API Gateway URL manually"
    echo "  -i, --iot-endpoint ENDPOINT  Set IoT endpoint manually"
    echo "  -r, --region REGION Set AWS region (default: us-east-1)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run with auto-detection"
    echo "  $0 -u https://abc123.execute-api.us-east-1.amazonaws.com"
    echo "  $0 -i abc123.iot.us-east-1.amazonaws.com"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -u|--api-url)
            API_BASE_URL="$2"
            shift 2
            ;;
        -i|--iot-endpoint)
            IOT_ENDPOINT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if bc is installed for floating point math
if ! command -v bc &> /dev/null; then
    print_warning "bc is not installed. Using integer math for sample data generation."
    # Override generate_sample_data function to use integer math
    generate_sample_data() {
        local device_id=$1
        local timestamp=$2
        
        cat << EOF
{
    "device_id": "$device_id",
    "timestamp": "$timestamp",
    "temperature": $((RANDOM % 50 + 10)),
    "humidity": $((RANDOM % 40 + 30))
}
EOF
    }
fi

# Run tests
run_tests 