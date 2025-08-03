#!/bin/bash

# =============================================================================
# Generate and Push Sample IoT Data for Testing
# =============================================================================

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration từ terraform.tfvars
PROJECT_NAME="iot_data_platform"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
IOT_ENDPOINT=""
DEVICE_COUNT=10
HOURS_BACK=48
DATA_INTERVAL=60  # 1 phút giữa các lần gửi data
TOPIC="iot/data"
VERBOSE=false
LOG_FILE="iot_data_generation_$(date +%Y%m%d_%H%M%S).log"
TEST_MODE=false

# Device Types và Data Patterns
DEVICE_TYPES=(
    "temperature_sensor:temperature,humidity,pressure"
    "air_quality_sensor:pm25,pm10,co2,tvoc"
    "smart_thermostat:temperature,humidity,setpoint,status"
    "smart_light:brightness,color_temp,status,power_consumption"
    "motion_sensor:motion_detected,light_level,battery_level"
    "smart_plug:power_consumption,voltage,current,status"
    "weather_station:temperature,humidity,pressure,wind_speed,rainfall"
    "smart_camera:motion_detected,image_url,recording_status"
)

# Function to print colored output with timestamp
print_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[INFO][$timestamp]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS][$timestamp]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR][$timestamp]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING][$timestamp]${NC} $1" | tee -a "$LOG_FILE"
}

print_debug() {
    if [ "$VERBOSE" = true ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${PURPLE}[DEBUG][$timestamp]${NC} $1" | tee -a "$LOG_FILE"
    fi
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

# Check optional tools
if ! command -v jq &> /dev/null; then
    print_warning "jq is not installed. JSON parsing will be limited."
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

# Function to validate AWS credentials
validate_aws_credentials() {
    print_info "Validating AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        print_info "Please run: aws configure"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    local user_arn=$(aws sts get-caller-identity --query 'Arn' --output text)
    print_success "AWS credentials valid - Account: $account_id, User: $user_arn"
}

# Function to get IoT endpoint
get_iot_endpoint() {
    print_info "Getting IoT Endpoint..."
    
    IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --region $AWS_REGION --query 'endpointAddress' --output text 2>/dev/null)
    
    if [ -n "$IOT_ENDPOINT" ] && [ "$IOT_ENDPOINT" != "None" ]; then
        print_success "IoT Endpoint: $IOT_ENDPOINT"
        return 0
    else
        print_warning "Could not get IoT endpoint automatically."
        print_info "Please set IOT_ENDPOINT manually or check your AWS configuration."
        return 1
    fi
}

# Function to test IoT endpoint connectivity
test_iot_endpoint() {
    local endpoint=$1
    local region=$2
    
    print_info "Testing IoT endpoint connectivity..."
    
    # Test basic connectivity
    if aws iot-data list-retained-messages --endpoint-url "https://$endpoint" --region $region &> /dev/null; then
        print_success "IoT endpoint connectivity verified"
        return 0
    else
        print_error "Cannot connect to IoT endpoint: $endpoint"
        print_error "Please check:"
        print_error "  1. AWS credentials are configured correctly"
        print_error "  2. IoT endpoint is correct"
        print_error "  3. AWS region matches the endpoint"
        print_error "  4. IoT Core is deployed and accessible"
        return 1
    fi
}

# Function to check and create IoT resources if needed
check_iot_resources() {
    print_info "Checking IoT resources..."
    
    # Check if IoT policy exists
    local policy_name="${PROJECT_NAME}_iot_policy_${ENVIRONMENT}"
    if ! aws iot get-policy --policy-name "$policy_name" --region $AWS_REGION &> /dev/null; then
        print_warning "IoT policy not found: $policy_name"
        print_info "Please run terraform apply to create IoT resources"
        return 1
    fi
    
    # Check if IoT certificate exists
    local cert_count=$(aws iot list-certificates --region $AWS_REGION --query 'certificates[?status==`ACTIVE`] | length(@)' --output text 2>/dev/null || echo "0")
    if [ "$cert_count" -eq "0" ]; then
        print_warning "No active IoT certificates found"
        print_info "Please run terraform apply to create IoT certificates"
        return 1
    fi
    
    print_success "IoT resources verified"
    return 0
}

# Function to validate JSON format
validate_json() {
    local json_data=$1
    
    if [ "$JQ_AVAILABLE" = true ]; then
        if echo "$json_data" | jq . > /dev/null 2>&1; then
            return 0
        else
            print_error "Invalid JSON format detected"
            return 1
        fi
    else
        # Basic validation without jq
        if [[ "$json_data" =~ ^\{.*\}$ ]]; then
            return 0
        else
            print_error "Basic JSON validation failed"
            return 1
        fi
    fi
}



# Function to generate timestamp cross-platform compatible
generate_timestamp() {
    local hours_ago=$1
    local minutes_ago=$2
    
    # Check if we're on macOS (which uses different date syntax)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use -v option for date arithmetic
        date -u -v-${hours_ago}H -v-${minutes_ago}M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"
    else
        # Linux: use -d option
        date -u -d "${hours_ago} hours ago" -d "${minutes_ago} minutes ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"
    fi
}

# Function to save sample data to local file
save_sample_data() {
    local device_id=$1
    local device_type=$2
    local timestamp=$3
    local data=$4
    
    local sample_file="sample_data_${device_id}_$(date +%Y%m%d_%H%M%S).json"
    
    echo "$data" > "$sample_file"
    print_debug "Sample data saved to: $sample_file"
}

# Function to get Terraform outputs
get_terraform_outputs() {
    print_info "Getting Terraform outputs..."
    
    if [ -f "terraform.tfstate" ]; then
        local api_endpoint=$(terraform output -raw api_endpoint 2>/dev/null)
        local iot_endpoint=$(terraform output -raw iot_endpoint 2>/dev/null)
        local dynamodb_table=$(terraform output -raw dynamodb_table_name 2>/dev/null)
        local s3_bucket=$(terraform output -raw s3_bucket_name 2>/dev/null)
        local sqs_queue=$(terraform output -raw sqs_queue_url 2>/dev/null)
        
        if [ ! -z "$api_endpoint" ] && [ "$api_endpoint" != "None" ]; then
            print_success "API Endpoint: $api_endpoint"
        fi
        
        if [ ! -z "$iot_endpoint" ] && [ "$iot_endpoint" != "None" ]; then
            IOT_ENDPOINT=$(echo "$iot_endpoint" | sed 's|https://||')
            print_success "IoT Endpoint: $IOT_ENDPOINT"
        fi
        
        if [ ! -z "$dynamodb_table" ] && [ "$dynamodb_table" != "None" ]; then
            print_success "DynamoDB Table: $dynamodb_table"
        fi
        
        if [ ! -z "$s3_bucket" ] && [ "$s3_bucket" != "None" ]; then
            print_success "S3 Bucket: $s3_bucket"
        fi
        
        if [ ! -z "$sqs_queue" ] && [ "$sqs_queue" != "None" ]; then
            print_success "SQS Queue: $sqs_queue"
        fi
        
        return 0
    else
        print_warning "terraform.tfstate not found. Using default configuration."
        return 1
    fi
}

# Function to generate realistic sensor data based on device type
generate_sensor_data() {
    local device_type=$1
    local device_id=$2
    local timestamp=$3
    
    case $device_type in
        "temperature_sensor")
            local temp=$(echo "scale=1; $RANDOM % 30 + 15" | bc 2>/dev/null || echo $((RANDOM % 30 + 15)))
            local humidity=$(echo "scale=1; $RANDOM % 30 + 40" | bc 2>/dev/null || echo $((RANDOM % 30 + 40)))
            local pressure=$(echo "scale=1; $RANDOM % 50 + 1000" | bc 2>/dev/null || echo $((RANDOM % 50 + 1000)))
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "temperature": $temp,
    "humidity": $humidity,
    "pressure": $pressure,
    "battery_level": $((RANDOM % 20 + 80)),
    "location": {
        "latitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 10.0" | bc 2>/dev/null || echo "10.123456"),
        "longitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 106.0" | bc 2>/dev/null || echo "106.123456")
    }
}
EOF
            ;;
        "air_quality_sensor")
            local pm25=$((RANDOM % 50 + 10))
            local pm10=$((RANDOM % 100 + 20))
            local co2=$((RANDOM % 500 + 400))
            local tvoc=$((RANDOM % 100 + 10))
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "pm25": $pm25,
    "pm10": $pm10,
    "co2": $co2,
    "tvoc": $tvoc,
    "battery_level": $((RANDOM % 20 + 80)),
    "location": {
        "latitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 10.0" | bc 2>/dev/null || echo "10.123456"),
        "longitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 106.0" | bc 2>/dev/null || echo "106.123456")
    }
}
EOF
            ;;
        "smart_thermostat")
            local temp=$(echo "scale=1; $RANDOM % 10 + 20" | bc 2>/dev/null || echo $((RANDOM % 10 + 20)))
            local humidity=$((RANDOM % 20 + 40))
            local setpoint=$(echo "scale=1; $RANDOM % 5 + 22" | bc 2>/dev/null || echo $((RANDOM % 5 + 22)))
            local statuses=("heating" "cooling" "idle" "fan_only")
            local status=${statuses[$((RANDOM % 4))]}
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "temperature": $temp,
    "humidity": $humidity,
    "setpoint": $setpoint,
    "status": "$status",
    "battery_level": $((RANDOM % 20 + 80))
}
EOF
            ;;
        "smart_light")
            local brightness=$((RANDOM % 100 + 1))
            local color_temp=$((RANDOM % 4000 + 2000))
            local statuses=("on" "off" "dimmed")
            local status=${statuses[$((RANDOM % 3))]}
            local power_consumption=$(echo "scale=2; $RANDOM % 50 + 5" | bc 2>/dev/null || echo $((RANDOM % 50 + 5)))
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "brightness": $brightness,
    "color_temp": $color_temp,
    "status": "$status",
    "power_consumption": $power_consumption
}
EOF
            ;;
        "motion_sensor")
            local motion_detected=$((RANDOM % 2))
            local light_level=$((RANDOM % 1000 + 1))
            local battery_level=$((RANDOM % 20 + 80))
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "motion_detected": $motion_detected,
    "light_level": $light_level,
    "battery_level": $battery_level,
    "location": {
        "latitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 10.0" | bc 2>/dev/null || echo "10.123456"),
        "longitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 106.0" | bc 2>/dev/null || echo "106.123456")
    }
}
EOF
            ;;
        "smart_plug")
            local power_consumption=$(echo "scale=2; $RANDOM % 2000 + 100" | bc 2>/dev/null || echo $((RANDOM % 2000 + 100)))
            local voltage=$((RANDOM % 20 + 220))
            local current=$(echo "scale=2; $RANDOM % 10 + 0.5" | bc 2>/dev/null || echo $((RANDOM % 10 + 1)))
            local statuses=("on" "off" "standby")
            local status=${statuses[$((RANDOM % 3))]}
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "power_consumption": $power_consumption,
    "voltage": $voltage,
    "current": $current,
    "status": "$status"
}
EOF
            ;;
        "weather_station")
            local temp=$(echo "scale=1; $RANDOM % 40 - 10" | bc 2>/dev/null || echo $((RANDOM % 40 - 10)))
            local humidity=$((RANDOM % 40 + 30))
            local pressure=$(echo "scale=1; $RANDOM % 50 + 1000" | bc 2>/dev/null || echo $((RANDOM % 50 + 1000)))
            local wind_speed=$(echo "scale=1; $RANDOM % 30" | bc 2>/dev/null || echo $((RANDOM % 30)))
            local rainfall=$(echo "scale=2; $RANDOM % 50" | bc 2>/dev/null || echo $((RANDOM % 50)))
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "temperature": $temp,
    "humidity": $humidity,
    "pressure": $pressure,
    "wind_speed": $wind_speed,
    "rainfall": $rainfall,
    "location": {
        "latitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 10.0" | bc 2>/dev/null || echo "10.123456"),
        "longitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 106.0" | bc 2>/dev/null || echo "106.123456")
    }
}
EOF
            ;;
        "smart_camera")
            local motion_detected=$((RANDOM % 2))
            local recording_statuses=("recording" "idle" "motion_detected")
            local recording_status=${recording_statuses[$((RANDOM % 3))]}
            local image_url="https://example.com/images/${device_id}_$(date +%s).jpg"
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "motion_detected": $motion_detected,
    "recording_status": "$recording_status",
    "image_url": "$image_url",
    "battery_level": $((RANDOM % 20 + 80))
}
EOF
            ;;
        *)
            # Default generic sensor
            local temp=$(echo "scale=1; $RANDOM % 50 + 10" | bc 2>/dev/null || echo $((RANDOM % 50 + 10)))
            local humidity=$(echo "scale=1; $RANDOM % 40 + 30" | bc 2>/dev/null || echo $((RANDOM % 40 + 30)))
            cat << EOF
{
    "device_id": "$device_id",
    "device_type": "$device_type",
    "timestamp": "$timestamp",
    "temperature": $temp,
    "humidity": $humidity,
    "battery_level": $((RANDOM % 20 + 80)),
    "location": {
        "latitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 10.0" | bc 2>/dev/null || echo "10.123456"),
        "longitude": $(echo "scale=6; $RANDOM % 1000 / 10000 + 106.0" | bc 2>/dev/null || echo "106.123456")
    }
}
EOF
            ;;
    esac
}

# Function to push data to IoT Core
push_iot_data() {
    local device_id=$1
    local device_type=$2
    local timestamp=$3
    local data=$4
    
    local topic="iot/data/$device_type"
    
    # Debug: Print the command being executed
    if [ "$VERBOSE" = true ]; then
        print_debug "Publishing to topic: $topic"
        print_debug "Endpoint: https://$IOT_ENDPOINT"
        print_debug "Data length: ${#data} characters"
    fi
    
    # Test mode: just simulate publishing
    if [ "$TEST_MODE" = true ]; then
        print_debug "TEST MODE: Simulating publish for $device_id to topic $topic"
        return 0
    fi
    
    # Test IoT endpoint connectivity first
    if ! aws iot-data list-retained-messages --endpoint-url "https://$IOT_ENDPOINT" --region $AWS_REGION &> /dev/null; then
        print_error "Cannot connect to IoT endpoint: $IOT_ENDPOINT"
        print_error "Please check your AWS credentials and IoT endpoint"
        return 1
    fi
    
    # Create temporary file for payload to avoid shell escaping issues
    local temp_file=$(mktemp)
    echo "$data" > "$temp_file"
    
    # Publish data using file method
    if aws iot-data publish \
        --endpoint-url "https://$IOT_ENDPOINT" \
        --topic "$topic" \
        --payload file://"$temp_file" \
        --region $AWS_REGION 2>&1 | tee -a "$LOG_FILE"; then
        
        print_debug "Published data for $device_id to topic $topic"
        rm -f "$temp_file"
        return 0
    else
        local exit_code=$?
        print_error "Failed to publish data for $device_id (exit code: $exit_code)"
        print_error "Topic: $topic"
        print_error "Endpoint: $IOT_ENDPOINT"
        print_error "Data sample: $(echo "$data" | head -c 100)..."
        rm -f "$temp_file"
        return 1
    fi
}

# Function to generate device configurations
generate_device_configs() {
    local devices=()
    local device_types=()
    
    # Generate device configurations
    for i in $(seq 1 $DEVICE_COUNT); do
        local device_type_idx=$((RANDOM % ${#DEVICE_TYPES[@]}))
        local device_type=$(echo "${DEVICE_TYPES[$device_type_idx]}" | cut -d: -f1)
        local device_id="${device_type}_$(printf "%03d" $i)"
        
        devices+=("$device_id")
        device_types+=("$device_type")
    done
    
    echo "${devices[@]}"
    echo "${device_types[@]}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -e, --endpoint ENDPOINT Set IoT endpoint manually"
    echo "  -d, --devices COUNT     Set number of devices (default: 10)"
    echo "  -t, --hours HOURS       Set hours back to generate data (default: 48)"
    echo "  -r, --region REGION     Set AWS region (default: us-east-1)"
    echo "  -i, --interval SECONDS  Set interval between data points (default: 60)"
    echo "  -p, --project NAME      Set project name (default: iot_data_platform)"
    echo "  -env, --environment ENV Set environment (default: dev)"
    echo "  --topic TOPIC           Set IoT topic (default: iot/data)"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -l, --log-file FILE     Set custom log file"
    echo "  --test-mode             Test mode (generate data without sending)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run with auto-detection"
    echo "  $0 -e abc123.iot.us-east-1.amazonaws.com"
    echo "  $0 -d 20 -t 72                       # 20 devices, 72 hours back"
    echo "  $0 -i 30                             # Send data every 30 seconds"
    echo "  $0 -p my-iot-project -env prod       # Custom project and environment"
    echo "  $0 -v                                # Verbose output"
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
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -l|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --test-mode)
            TEST_MODE=true
            shift
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
fi

# Main execution
main() {
    local start_time=$(date +%s)
    
    print_info "Starting IoT Data Generation for Testing..."
    echo "=============================================="
    
    # Initialize log file
    echo "IoT Data Generation Log - $(date)" > "$LOG_FILE"
    
    # Validate AWS credentials
    validate_aws_credentials
    
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
    
    # Validate IoT endpoint connectivity
    if ! test_iot_endpoint "$IOT_ENDPOINT" "$AWS_REGION"; then
        exit 1
    fi
    
    # Check IoT resources
    if ! check_iot_resources; then
        print_warning "IoT resources may not be properly configured"
        print_info "Continuing with data generation anyway..."
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
    print_info "  Log File: $LOG_FILE"
    print_info "  Test Mode: $TEST_MODE"
    echo ""
    
    # Generate device configurations
    print_info "Generating device configurations..."
    local device_configs=$(generate_device_configs)
    local devices=($(echo "$device_configs" | head -n1))
    local device_types=($(echo "$device_configs" | tail -n1))
    
    print_info "Generated ${#devices[@]} devices:"
    for i in "${!devices[@]}"; do
        print_debug "  ${devices[$i]} (${device_types[$i]})"
    done
    echo ""
    
    local total_records=0
    local success_count=0
    local error_count=0
    
    # Generate data for each device
    for i in "${!devices[@]}"; do
        local device_id="${devices[$i]}"
        local device_type="${device_types[$i]}"
        
        print_info "Generating data for $device_id (type: $device_type)..."
        
        # Generate data for each hour
        for hour in $(seq 0 $((HOURS_BACK - 1))); do
            # Generate timestamp (more recent data more frequent)
            local hours_ago=$hour
            local minutes_ago=$((RANDOM % 60))
            # Use cross-platform compatible timestamp generation
            local timestamp=$(generate_timestamp "$hours_ago" "$minutes_ago")
            
            # Generate sensor data using temporary file to avoid shell escaping issues
            local temp_data_file=$(mktemp)
            generate_sensor_data "$device_type" "$device_id" "$timestamp" > "$temp_data_file"
            local data=$(cat "$temp_data_file")
            
            # Validate JSON format
            if ! validate_json "$data"; then
                print_error "Invalid JSON generated for $device_id, skipping..."
                rm -f "$temp_data_file"
                continue
            fi
            
            # Save sample data in test mode
            if [ "$TEST_MODE" = true ]; then
                save_sample_data "$device_id" "$device_type" "$timestamp" "$data"
            fi
            
            # Push data to IoT Core
            if push_iot_data "$device_id" "$device_type" "$timestamp" "$data"; then
                ((success_count++))
            else
                ((error_count++))
            fi
            
            # Clean up temporary file
            rm -f "$temp_data_file"
            
            ((total_records++))
            
            # Small delay to avoid overwhelming the system
            sleep 0.1
        done
        
        print_success "Completed data generation for $device_id"
        echo ""
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Data generation completed!"
    print_info "Summary:"
    print_info "  Total records: $total_records"
    print_info "  Successful: $success_count"
    print_info "  Failed: $error_count"
    print_info "  Duration: ${duration} seconds"
    echo ""
    
    if [ $success_count -gt 0 ]; then
        print_info "Next steps:"
        print_info "  1. Wait for data processing (45-60 seconds)"
        print_info "  2. Run test script: ./tests/test_iot_system.sh"
        print_info "  3. Check API endpoints:"
        print_info "     curl YOUR_API_URL/health"
        print_info "     curl YOUR_API_URL/devices"
        print_info "     curl YOUR_API_URL/devices/${devices[0]}"
    fi
    
    # Generate summary report
    local report_file="iot_data_generation_report_$(date +%Y%m%d_%H%M%S).json"
    cat > "$report_file" << EOF
{
    "generation_info": {
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
        "project_name": "$PROJECT_NAME",
        "environment": "$ENVIRONMENT",
        "aws_region": "$AWS_REGION",
        "iot_endpoint": "$IOT_ENDPOINT"
    },
    "configuration": {
        "device_count": $DEVICE_COUNT,
        "hours_back": $HOURS_BACK,
        "data_interval": $DATA_INTERVAL,
        "topic": "$TOPIC"
    },
    "results": {
        "total_records": $total_records,
        "successful": $success_count,
        "failed": $error_count,
        "duration_seconds": $duration
    },
    "devices": [
EOF
    
    for i in "${!devices[@]}"; do
        echo "        {\"device_id\": \"${devices[$i]}\", \"device_type\": \"${device_types[$i]}\"}" >> "$report_file"
        if [ $i -lt $((${#devices[@]} - 1)) ]; then
            echo "," >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF
    ]
}
EOF
    
    print_success "Generation report saved to: $report_file"
}

# Run main function
main 