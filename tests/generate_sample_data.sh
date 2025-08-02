#!/bin/bash

# =============================================================================
# Generate and Push Sample IoT Data
# =============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration - Default values từ Terraform
PROJECT_NAME="iot-data-platform"
ENVIRONMENT="dev"
AWS_REGION="us-east-2"
IOT_ENDPOINT=""
DEVICE_COUNT=5
HOURS_BACK=24
DATA_INTERVAL=300  # 5 phút giữa các lần gửi data
TOPIC="iot/data"

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

# Function to generate random temperature (10-60°C)
generate_temperature() {
    echo $(echo "scale=1; $RANDOM % 50 + 10" | bc 2>/dev/null || echo $((RANDOM % 50 + 10)))
}

# Function to generate random humidity (30-90%)
generate_humidity() {
    echo $(echo "scale=1; $RANDOM % 60 + 30" | bc 2>/dev/null || echo $((RANDOM % 60 + 30)))
}

# Function to generate random pressure (900-1100 hPa)
generate_pressure() {
    echo $(echo "scale=1; $RANDOM % 200 + 900" | bc 2>/dev/null || echo $((RANDOM % 200 + 900)))
}

# Function to generate sample data JSON
generate_sample_data() {
    local device_id=$1
    local timestamp=$2
    local temperature=$3
    local humidity=$4
    local pressure=$5
    
    cat << EOF
{
    "device_id": "$device_id",
    "timestamp": "$timestamp",
    "temperature": $temperature,
    "humidity": $humidity,
    "pressure": $pressure,
    "location": {
        "latitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 10.0" | bc 2>/dev/null || echo "10.123456"),
        "longitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 106.0" | bc 2>/dev/null || echo "106.123456")
    },
    "battery_level": $(echo "scale=1; $RANDOM % 40 + 60" | bc 2>/dev/null || echo $((RANDOM % 40 + 60))),
    "signal_strength": $(echo "scale=1; $RANDOM % 30 + 70" | bc 2>/dev/null || echo $((RANDOM % 30 + 70)))
}
EOF
}

# Function to push data to IoT Core
push_data() {
    local device_id=$1
    local timestamp=$2
    local temperature=$3
    local humidity=$4
    local pressure=$5
    
    local payload=$(generate_sample_data "$device_id" "$timestamp" "$temperature" "$humidity" "$pressure")
    
    aws iot-data publish \
        --endpoint-url "https://$IOT_ENDPOINT" \
        --topic "$TOPIC" \
        --payload "$payload" \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "Data published for $device_id at $timestamp"
        return 0
    else
        print_error "Failed to publish data for $device_id"
        return 1
    fi
}

# Function to get IoT endpoint
get_iot_endpoint() {
    print_info "Getting IoT Endpoint..."
    
    IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --region $AWS_REGION --query 'endpointAddress' --output text 2>/dev/null)
    
    if [ -z "$IOT_ENDPOINT" ]; then
        print_warning "Could not get IoT endpoint automatically."
        print_info "Please set IOT_ENDPOINT manually or check your AWS configuration."
        return 1
    fi
    
    print_success "IoT Endpoint: $IOT_ENDPOINT"
    return 0
}

# Function to check AWS credentials
check_aws_credentials() {
    print_info "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &>/dev/null; then
        print_error "AWS credentials not configured or invalid."
        print_info "Please run: aws configure"
        return 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    local user_arn=$(aws sts get-caller-identity --query 'Arn' --output text)
    
    print_success "AWS Account: $account_id"
    print_success "User: $user_arn"
    return 0
}

# Function to check required tools
check_requirements() {
    print_info "Checking required tools..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install missing tools and try again."
        return 1
    fi
    
    print_success "All required tools are available"
    return 0
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -e, --endpoint ENDPOINT Set IoT endpoint manually"
    echo "  -d, --devices COUNT     Set number of devices (default: 5)"
    echo "  -t, --hours HOURS       Set hours back to generate data (default: 24)"
    echo "  -r, --region REGION     Set AWS region (default: us-east-2)"
    echo "  -i, --interval SECONDS  Set interval between data points (default: 300)"
    echo "  -p, --project NAME      Set project name (default: iot-data-platform)"
    echo "  -env, --environment ENV Set environment (default: dev)"
    echo "  --topic TOPIC           Set IoT topic (default: iot/data)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run with auto-detection"
    echo "  $0 -e abc123.iot.us-east-2.amazonaws.com"
    echo "  $0 -d 10 -t 48                       # 10 devices, 48 hours back"
    echo "  $0 -i 60                             # Send data every 60 seconds"
    echo "  $0 -p my-iot-project -env prod       # Custom project and environment"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -e|--endpoint)
            IOT_ENDPOINT="$2"
            shift 2
            ;;
        -d|--devices)
            DEVICE_COUNT="$2"
            shift 2
            ;;
        -t|--hours)
            HOURS_BACK="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -i|--interval)
            DATA_INTERVAL="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -env|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --topic)
            TOPIC="$2"
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
    # Override functions to use integer math
    generate_temperature() {
        echo $((RANDOM % 50 + 10))
    }
    
    generate_humidity() {
        echo $((RANDOM % 60 + 30))
    }
    
    generate_pressure() {
        echo $((RANDOM % 200 + 900))
    }
fi

# Function to get Terraform outputs
get_terraform_outputs() {
    print_info "Getting Terraform outputs..."
    
    if [ -f "terraform.tfstate" ]; then
        local api_endpoint=$(terraform output -raw api_endpoint 2>/dev/null)
        local iot_endpoint=$(terraform output -raw iot_endpoint 2>/dev/null)
        local kinesis_stream=$(terraform output -raw kinesis_stream_name 2>/dev/null)
        local dynamodb_table=$(terraform output -raw dynamodb_table_name 2>/dev/null)
        local s3_bucket=$(terraform output -raw s3_bucket_name 2>/dev/null)
        
        if [ ! -z "$api_endpoint" ]; then
            print_success "API Endpoint: $api_endpoint"
        fi
        
        if [ ! -z "$iot_endpoint" ]; then
            IOT_ENDPOINT=$(echo "$iot_endpoint" | sed 's|https://||')
            print_success "IoT Endpoint: $IOT_ENDPOINT"
        fi
        
        if [ ! -z "$kinesis_stream" ]; then
            print_success "Kinesis Stream: $kinesis_stream"
        fi
        
        if [ ! -z "$dynamodb_table" ]; then
            print_success "DynamoDB Table: $dynamodb_table"
        fi
        
        if [ ! -z "$s3_bucket" ]; then
            print_success "S3 Bucket: $s3_bucket"
        fi
        
        return 0
    else
        print_warning "terraform.tfstate not found. Using default configuration."
        return 1
    fi
}

# Main execution
main() {
    print_info "Starting IoT Data Generation..."
    echo "=================================="
    
    # Check requirements
    check_requirements || exit 1
    
    # Check AWS credentials
    check_aws_credentials || exit 1
    
    # Try to get Terraform outputs
    get_terraform_outputs
    
    # Get IoT endpoint if not provided
    if [ -z "$IOT_ENDPOINT" ]; then
        get_iot_endpoint
        if [ $? -ne 0 ]; then
            print_error "IoT endpoint is required. Please provide it with -e option."
            exit 1
        fi
    fi
    
    print_info "Configuration:"
    print_info "  Project Name: $PROJECT_NAME"
    print_info "  Environment: $ENVIRONMENT"
    print_info "  IoT Endpoint: $IOT_ENDPOINT"
    print_info "  AWS Region: $AWS_REGION"
    print_info "  Device Count: $DEVICE_COUNT"
    print_info "  Hours Back: $HOURS_BACK"
    print_info "  Data Interval: ${DATA_INTERVAL}s"
    print_info "  Topic: $TOPIC"
    echo ""
    
    local total_records=0
    local success_count=0
    local error_count=0
    
    # Generate data for each device
    for device_num in $(seq 1 $DEVICE_COUNT); do
        device_id="sensor-$(printf "%03d" $device_num)"
        print_info "Generating data for $device_id..."
        
        # Generate data for each hour
        for hour in $(seq 0 $((HOURS_BACK - 1))); do
            timestamp=$(date -u -d "$hour hours ago" +"%Y-%m-%dT%H:%M:%SZ")
            temperature=$(generate_temperature)
            humidity=$(generate_humidity)
            pressure=$(generate_pressure)
            
            if push_data "$device_id" "$timestamp" "$temperature" "$humidity" "$pressure"; then
                ((success_count++))
            else
                ((error_count++))
            fi
            
            ((total_records++))
            
            # Small delay to avoid overwhelming the system
            sleep 0.2
        done
        
        print_success "Completed data generation for $device_id"
        echo ""
    done
    
    print_success "Data generation completed!"
    print_info "Summary:"
    print_info "  Total records: $total_records"
    print_info "  Successful: $success_count"
    print_info "  Failed: $error_count"
    echo ""
    
    if [ $success_count -gt 0 ]; then
        print_info "You can now test the API endpoints:"
        print_info "  curl YOUR_API_URL/health"
        print_info "  curl YOUR_API_URL/devices"
        print_info "  curl YOUR_API_URL/devices/sensor-001"
        print_info "  curl YOUR_API_URL/devices/sensor-001/data?hours=24"
    fi
}

# Run main function
main 