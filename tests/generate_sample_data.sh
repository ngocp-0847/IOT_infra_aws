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

# Configuration
IOT_ENDPOINT=""
AWS_REGION="us-east-1"
DEVICE_COUNT=5
HOURS_BACK=24

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

# Function to generate sample data JSON
generate_sample_data() {
    local device_id=$1
    local timestamp=$2
    local temperature=$3
    local humidity=$4
    
    cat << EOF
{
    "device_id": "$device_id",
    "timestamp": "$timestamp",
    "temperature": $temperature,
    "humidity": $humidity
}
EOF
}

# Function to push data to IoT Core
push_data() {
    local device_id=$1
    local timestamp=$2
    local temperature=$3
    local humidity=$4
    
    local payload=$(generate_sample_data "$device_id" "$timestamp" "$temperature" "$humidity")
    
    aws iot-data publish \
        --endpoint-url "https://$IOT_ENDPOINT" \
        --topic "iot/data" \
        --payload "$payload" \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "Data published for $device_id at $timestamp"
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -e, --endpoint ENDPOINT  Set IoT endpoint manually"
    echo "  -d, --devices COUNT Set number of devices (default: 5)"
    echo "  -t, --hours HOURS   Set hours back to generate data (default: 24)"
    echo "  -r, --region REGION Set AWS region (default: us-east-1)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run with auto-detection"
    echo "  $0 -e abc123.iot.us-east-1.amazonaws.com"
    echo "  $0 -d 10 -t 48                       # 10 devices, 48 hours back"
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
fi

# Main execution
main() {
    print_info "Starting IoT Data Generation..."
    echo "=================================="
    
    # Get IoT endpoint if not provided
    if [ -z "$IOT_ENDPOINT" ]; then
        get_iot_endpoint
        if [ $? -ne 0 ]; then
            print_error "IoT endpoint is required. Please provide it with -e option."
            exit 1
        fi
    fi
    
    print_info "Configuration:"
    print_info "  IoT Endpoint: $IOT_ENDPOINT"
    print_info "  AWS Region: $AWS_REGION"
    print_info "  Device Count: $DEVICE_COUNT"
    print_info "  Hours Back: $HOURS_BACK"
    echo ""
    
    # Generate data for each device
    for device_num in $(seq 1 $DEVICE_COUNT); do
        device_id="sensor-$(printf "%03d" $device_num)"
        print_info "Generating data for $device_id..."
        
        # Generate data for each hour
        for hour in $(seq 0 $((HOURS_BACK - 1))); do
            timestamp=$(date -u -d "$hour hours ago" +"%Y-%m-%dT%H:%M:%SZ")
            temperature=$(generate_temperature)
            humidity=$(generate_humidity)
            
            push_data "$device_id" "$timestamp" "$temperature" "$humidity"
            
            # Small delay to avoid overwhelming the system
            sleep 0.2
        done
        
        print_success "Completed data generation for $device_id"
        echo ""
    done
    
    print_success "Data generation completed!"
    print_info "Total records generated: $((DEVICE_COUNT * HOURS_BACK))"
    echo ""
    print_info "You can now test the API endpoints:"
    print_info "  curl YOUR_API_URL/health"
    print_info "  curl YOUR_API_URL/devices"
    print_info "  curl YOUR_API_URL/devices/sensor-001"
}

# Run main function
main 