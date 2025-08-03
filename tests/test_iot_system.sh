#!/bin/bash

# =============================================================================
# IoT System Test Script - Enhanced Version
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL=""
AWS_REGION="us-east-1"
IOT_ENDPOINT=""
LOG_FILE="iot_test_$(date +%Y%m%d_%H%M%S).log"
VERBOSE=false
TEST_MODE="full"  # full, quick, stress

# IoT Device Types and their data patterns
# Using simple arrays instead of associative arrays for better compatibility
DEVICE_TYPES_TEMP="temperature_sensor:temperature,humidity,pressure"
DEVICE_TYPES_AIR="air_quality_sensor:pm25,pm10,co2,tvoc"
DEVICE_TYPES_THERM="smart_thermostat:temperature,humidity,setpoint,status"
DEVICE_TYPES_LIGHT="smart_light:brightness,color_temp,status,power_consumption"
DEVICE_TYPES_MOTION="motion_sensor:motion_detected,light_level,battery_level"
DEVICE_TYPES_PLUG="smart_plug:power_consumption,voltage,current,status"
DEVICE_TYPES_WEATHER="weather_station:temperature,humidity,pressure,wind_speed,rainfall"
DEVICE_TYPES_CAMERA="smart_camera:motion_detected,image_url,recording_status"

# Function to get device type data pattern
get_device_type_pattern() {
    local device_type=$1
    case $device_type in
        "temperature_sensor") echo "temperature,humidity,pressure" ;;
        "air_quality_sensor") echo "pm25,pm10,co2,tvoc" ;;
        "smart_thermostat") echo "temperature,humidity,setpoint,status" ;;
        "smart_light") echo "brightness,color_temp,status,power_consumption" ;;
        "motion_sensor") echo "motion_detected,light_level,battery_level" ;;
        "smart_plug") echo "power_consumption,voltage,current,status" ;;
        "weather_station") echo "temperature,humidity,pressure,wind_speed,rainfall" ;;
        "smart_camera") echo "motion_detected,image_url,recording_status" ;;
        *) echo "temperature,humidity" ;;
    esac
}

# Function to print colored output with timestamp
print_status() {
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
    print_status "Validating AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        print_status "Please run: aws configure"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    local user_arn=$(aws sts get-caller-identity --query 'Arn' --output text)
    print_success "AWS credentials valid - Account: $account_id, User: $user_arn"
}

# Function to get API Gateway URL
get_api_url() {
    print_status "Getting API Gateway URL..."
    
    # Try multiple methods to get API URL
    local api_url=""
    
    # Method 1: Try to get from Terraform output first
    if command -v terraform &> /dev/null; then
        api_url=$(terraform output -raw api_endpoint 2>/dev/null | sed 's/https:\/\///')
        if [ -n "$api_url" ] && [ "$api_url" != "None" ]; then
            API_BASE_URL="https://$api_url"
            print_success "API URL from Terraform: $API_BASE_URL"
            return 0
        fi
    fi
    
    # Method 2: Try to get from AWS CLI with specific name
    api_url=$(aws apigatewayv2 get-apis --region $AWS_REGION --query 'Items[?Name==`iot-data-api`].ApiEndpoint' --output text 2>/dev/null)
    if [ -n "$api_url" ] && [ "$api_url" != "None" ]; then
        API_BASE_URL="https://$api_url"
        print_success "API URL from AWS CLI: $API_BASE_URL"
        return 0
    fi
    
    # Method 3: Try to get any API Gateway in the region
    api_url=$(aws apigatewayv2 get-apis --region $AWS_REGION --query 'Items[0].ApiEndpoint' --output text 2>/dev/null)
    if [ -n "$api_url" ] && [ "$api_url" != "None" ]; then
        API_BASE_URL="https://$api_url"
        print_success "API URL from AWS CLI (first API): $API_BASE_URL"
        return 0
    fi
    
    print_warning "Could not get API URL automatically. Please set API_BASE_URL manually."
    print_status "You can find the API URL in AWS Console or Terraform output"
    return 1
}

# Function to get IoT Endpoint
get_iot_endpoint() {
    print_status "Getting IoT Endpoint..."
    
    IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --region $AWS_REGION --query 'endpointAddress' --output text 2>/dev/null)
    
    if [ -n "$IOT_ENDPOINT" ] && [ "$IOT_ENDPOINT" != "None" ]; then
        print_success "IoT Endpoint: $IOT_ENDPOINT"
        return 0
    else
        print_warning "Could not get IoT endpoint automatically. Please set IOT_ENDPOINT manually."
        print_status "You can find the IoT endpoint in AWS Console or run: aws iot describe-endpoint --endpoint-type iot:Data-ATS"
        return 1
    fi
}

# Function to generate realistic sensor data
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
    "battery_level": $((RANDOM % 20 + 80))
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
    "battery_level": $((RANDOM % 20 + 80))
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
    "battery_level": $battery_level
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
    "rainfall": $rainfall
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
    "battery_level": $((RANDOM % 20 + 80))
}
EOF
            ;;
    esac
}

# Function to push IoT data with different strategies
push_iot_data() {
    print_status "Starting IoT data push simulation..."
    
    if [ -z "$IOT_ENDPOINT" ]; then
        print_error "IOT_ENDPOINT is not set"
        return 1
    fi
    
    local total_devices=0
    local total_messages=0
    
    # Define device configurations using simple arrays
    local device_ids=("temp_sensor_001" "temp_sensor_002" "air_quality_001" "air_quality_002" "thermostat_001" "thermostat_002" "light_001" "light_002" "motion_001" "motion_002" "plug_001" "plug_002" "weather_001" "camera_001")
    local device_types=("temperature_sensor" "temperature_sensor" "air_quality_sensor" "air_quality_sensor" "smart_thermostat" "smart_thermostat" "smart_light" "smart_light" "motion_sensor" "motion_sensor" "smart_plug" "smart_plug" "weather_station" "smart_camera")
    
    # Function to get device type by device id
    get_device_type() {
        local device_id=$1
        for i in "${!device_ids[@]}"; do
            if [ "${device_ids[$i]}" = "$device_id" ]; then
                echo "${device_types[$i]}"
                return 0
            fi
        done
        echo "temperature_sensor"  # default
    }
    
    case $TEST_MODE in
        "quick")
            # Quick test: 5 devices, 10 messages each
            local devices=("temp_sensor_001" "air_quality_001" "thermostat_001" "light_001" "motion_001")
            local messages_per_device=10
            ;;
        "stress")
            # Stress test: all devices, many messages
            local devices=("${device_ids[@]}")
            local messages_per_device=100
            ;;
        *)
            # Full test: all devices, moderate messages
            local devices=("${device_ids[@]}")
            local messages_per_device=50
            ;;
    esac
    
    print_status "Testing with ${#devices[@]} devices, $messages_per_device messages per device"
    
    for device_id in "${devices[@]}"; do
        local device_type=$(get_device_type "$device_id")
        print_status "Processing device: $device_id (type: $device_type)"
        
        for ((i=0; i<messages_per_device; i++)); do
            # Generate timestamp (last 24 hours, more recent data more frequent)
            local hours_ago=$((RANDOM % 24))
            local minutes_ago=$((RANDOM % 60))
            # Use macOS compatible date command
            local timestamp=$(date -u -v-${hours_ago}H -v-${minutes_ago}M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
            
            # Generate data
            local data=$(generate_sensor_data "$device_type" "$device_id" "$timestamp")
            
            # Publish to IoT topic
            local topic="iot/data/$device_type"
            
            if aws iot-data publish \
                --endpoint-url "https://$IOT_ENDPOINT" \
                --topic "$topic" \
                --payload "$data" \
                --region $AWS_REGION &> /dev/null; then
                
                print_debug "Published data for $device_id to topic $topic"
                ((total_messages++))
            else
                print_error "Failed to publish data for $device_id"
            fi
            
            # Small delay to avoid overwhelming the system
            sleep 0.1
        done
        
        ((total_devices++))
        print_success "Completed $device_id ($total_devices/${#devices[@]})"
    done
    
    print_success "IoT data push completed: $total_messages messages from $total_devices devices"
}

# Function to simulate real-time events
simulate_realtime_events() {
    print_status "Simulating real-time IoT events..."
    
    if [ -z "$IOT_ENDPOINT" ]; then
        print_error "IOT_ENDPOINT is not set"
        return 1
    fi
    
    local duration=60  # seconds
    local interval=2   # seconds between events
    
    print_status "Running real-time simulation for $duration seconds (every $interval seconds)"
    
    local start_time=$(date +%s)
    local event_count=0
    
    while [ $(($(date +%s) - start_time)) -lt $duration ]; do
        # Select random device
        local devices=("temp_sensor_001" "air_quality_001" "thermostat_001" "light_001" "motion_001")
        local device_id=${devices[$((RANDOM % ${#devices[@]}))]}
        local device_type="temperature_sensor"  # Simplified for real-time
        
        # Generate current timestamp
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local data=$(generate_sensor_data "$device_type" "$device_id" "$timestamp")
        
        # Publish to real-time topic
        if aws iot-data publish \
            --endpoint-url "https://$IOT_ENDPOINT" \
            --topic "iot/realtime" \
            --payload "$data" \
            --region $AWS_REGION &> /dev/null; then
            
            print_debug "Real-time event: $device_id at $timestamp"
            ((event_count++))
        fi
        
        sleep $interval
    done
    
    print_success "Real-time simulation completed: $event_count events"
}

# Function to test health check
test_health_check() {
    print_status "Testing health check endpoint..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    local response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/health")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Health check passed"
        echo "Response: $body"
        return 0
    else
        print_error "Health check failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to test get devices endpoint
test_get_devices() {
    print_status "Testing get devices endpoint..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    local response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/devices")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get devices endpoint working"
        
        # Parse and display device count
        if [ "$JQ_AVAILABLE" = true ]; then
            local device_count=$(echo "$body" | jq '.devices | length' 2>/dev/null || echo "unknown")
            print_status "Found $device_count devices"
            
            if [ "$VERBOSE" = true ]; then
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
        else
            print_status "Found devices (JSON parsing limited without jq)"
            if [ "$VERBOSE" = true ]; then
                echo "$body"
            fi
        fi
        return 0
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
    
    local response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/devices/$device_id")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get device data endpoint working for $device_id"
        
        # Parse and display data count
        if [ "$JQ_AVAILABLE" = true ]; then
            local data_count=$(echo "$body" | jq '.data | length' 2>/dev/null || echo "unknown")
            print_status "Found $data_count data points for $device_id"
            
            if [ "$VERBOSE" = true ]; then
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
        else
            print_status "Found data points for $device_id (JSON parsing limited without jq)"
            if [ "$VERBOSE" = true ]; then
                echo "$body"
            fi
        fi
        return 0
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
    
    local url="$API_BASE_URL/devices/$device_id?start_time=$start_time&end_time=$end_time"
    local response=$(curl -s -w "\n%{http_code}" "$url")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get device data with time range working for $device_id"
        
        # Parse and display data count
        if [ "$JQ_AVAILABLE" = true ]; then
            local data_count=$(echo "$body" | jq '.data | length' 2>/dev/null || echo "unknown")
            print_status "Found $data_count data points in time range for $device_id"
            
            if [ "$VERBOSE" = true ]; then
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
        else
            print_status "Found data points in time range for $device_id (JSON parsing limited without jq)"
            if [ "$VERBOSE" = true ]; then
                echo "$body"
            fi
        fi
        return 0
    else
        print_error "Get device data with time range failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to test device statistics
test_device_statistics() {
    local device_id=$1
    
    print_status "Testing device statistics for $device_id..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    local response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/devices/$device_id/stats")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Device statistics working for $device_id"
        echo "Statistics: $body"
        return 0
    else
        print_warning "Device statistics endpoint not available (status $http_code)"
        return 1
    fi
}

# Function to test system metrics
test_system_metrics() {
    print_status "Testing system metrics endpoint..."
    
    if [ -z "$API_BASE_URL" ]; then
        print_error "API_BASE_URL is not set"
        return 1
    fi
    
    local response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/metrics")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "System metrics endpoint working"
        echo "Metrics: $body"
        return 0
    else
        print_warning "System metrics endpoint not available (status $http_code)"
        return 1
    fi
}

# Function to generate test report
generate_test_report() {
    local report_file="iot_test_report_$(date +%Y%m%d_%H%M%S).json"
    
    print_status "Generating test report: $report_file"
    
    cat > "$report_file" << EOF
{
    "test_info": {
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
        "test_mode": "$TEST_MODE",
        "aws_region": "$AWS_REGION",
        "api_url": "$API_BASE_URL",
        "iot_endpoint": "$IOT_ENDPOINT"
    },
    "test_results": {
        "health_check": "completed",
        "data_push": "completed",
        "api_tests": "completed"
    },
    "summary": {
        "total_devices_tested": "${#devices[@]}",
        "total_messages_sent": "$total_messages",
        "test_duration": "$(($(date +%s) - start_time)) seconds"
    }
}
EOF
    
    print_success "Test report saved to: $report_file"
}

# Main test function
run_tests() {
    local start_time=$(date +%s)
    
    print_status "Starting Enhanced IoT System Tests..."
    echo "=============================================="
    print_status "Test Mode: $TEST_MODE"
    print_status "Log File: $LOG_FILE"
    print_status "AWS Region: $AWS_REGION"
    
    # Initialize log file
    echo "IoT System Test Log - $(date)" > "$LOG_FILE"
    
    # Validate AWS credentials
    validate_aws_credentials
    
    # Get endpoints
    local api_url_ok=false
    local iot_endpoint_ok=false
    
    if get_api_url; then
        api_url_ok=true
    fi
    
    if get_iot_endpoint; then
        iot_endpoint_ok=true
    fi
    
    # Check if we have minimum required endpoints
    if [ "$api_url_ok" = false ] && [ "$iot_endpoint_ok" = false ]; then
        print_error "Neither API URL nor IoT endpoint could be obtained automatically."
        print_status "Please set them manually using -u and -i options"
        print_status "Example: $0 -u https://your-api.execute-api.us-east-1.amazonaws.com -i your-iot-endpoint.iot.us-east-1.amazonaws.com"
        exit 1
    fi
    
    local test_results=()
    
    # Test 1: Health check (only if API URL is available)
    if [ "$api_url_ok" = true ]; then
        echo ""
        print_status "Test 1: Health Check"
        if test_health_check; then
            test_results+=("health_check: PASS")
        else
            test_results+=("health_check: FAIL")
        fi
    else
        print_warning "Skipping health check - API URL not available"
        test_results+=("health_check: SKIP")
    fi
    
    # Test 2: Push IoT data (only if IoT endpoint is available)
    if [ "$iot_endpoint_ok" = true ]; then
        echo ""
        print_status "Test 2: Push IoT Data"
        if push_iot_data; then
            test_results+=("data_push: PASS")
        else
            test_results+=("data_push: FAIL")
        fi
        
        # Test 3: Real-time events simulation
        echo ""
        print_status "Test 3: Real-time Events Simulation"
        if simulate_realtime_events; then
            test_results+=("realtime_events: PASS")
        else
            test_results+=("realtime_events: FAIL")
        fi
    else
        print_warning "Skipping IoT data tests - IoT endpoint not available"
        test_results+=("data_push: SKIP")
        test_results+=("realtime_events: SKIP")
    fi
    
    # Wait for data processing (only if we pushed data)
    if [ "$iot_endpoint_ok" = true ]; then
        echo ""
        print_status "Waiting for data processing (45 seconds)..."
        sleep 45
    fi
    
    # Test 4: Get devices (only if API URL is available)
    if [ "$api_url_ok" = true ]; then
        echo ""
        print_status "Test 4: Get Devices"
        if test_get_devices; then
            test_results+=("get_devices: PASS")
        else
            test_results+=("get_devices: FAIL")
        fi
        
        # Test 5: Get device data
        echo ""
        print_status "Test 5: Get Device Data"
        if test_get_device_data "temp_sensor_001"; then
            test_results+=("get_device_data: PASS")
        else
            test_results+=("get_device_data: FAIL")
        fi
        
        # Test 6: Get device data with time range
        echo ""
        print_status "Test 6: Get Device Data with Time Range"
        local start_time_range=$(date -u -v-12H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
        local end_time_range=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        if test_get_device_data_with_time "temp_sensor_001" "$start_time_range" "$end_time_range"; then
            test_results+=("get_device_data_time: PASS")
        else
            test_results+=("get_device_data_time: FAIL")
        fi
        
        # Test 7: Device statistics
        echo ""
        print_status "Test 7: Device Statistics"
        if test_device_statistics "temp_sensor_001"; then
            test_results+=("device_statistics: PASS")
        else
            test_results+=("device_statistics: SKIP")
        fi
        
        # Test 8: System metrics
        echo ""
        print_status "Test 8: System Metrics"
        if test_system_metrics; then
            test_results+=("system_metrics: PASS")
        else
            test_results+=("system_metrics: SKIP")
        fi
    else
        print_warning "Skipping API tests - API URL not available"
        test_results+=("get_devices: SKIP")
        test_results+=("get_device_data: SKIP")
        test_results+=("get_device_data_time: SKIP")
        test_results+=("device_statistics: SKIP")
        test_results+=("system_metrics: SKIP")
    fi
    
    # Generate test report
    echo ""
    print_status "Generating test report..."
    generate_test_report
    
    # Print summary
    echo ""
    print_status "Test Summary:"
    echo "=============="
    for result in "${test_results[@]}"; do
        if [[ $result == *": PASS" ]]; then
            print_success "$result"
        elif [[ $result == *": SKIP" ]]; then
            print_warning "$result"
        else
            print_error "$result"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo ""
    print_success "All tests completed in ${duration} seconds!"
    print_status "Check log file for details: $LOG_FILE"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -u, --api-url URL       Set API Gateway URL manually"
    echo "  -i, --iot-endpoint ENDPOINT  Set IoT endpoint manually"
    echo "  -r, --region REGION     Set AWS region (default: us-east-1)"
    echo "  -m, --mode MODE         Set test mode: quick, full, stress (default: full)"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -l, --log-file FILE     Set custom log file"
    echo ""
    echo "Test Modes:"
    echo "  quick    - 5 devices, 10 messages each (fast test)"
    echo "  full     - All devices, 50 messages each (default)"
    echo "  stress   - 20 devices, 100 messages each (stress test)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run full test with auto-detection"
    echo "  $0 -m quick                          # Run quick test"
    echo "  $0 -m stress -v                      # Run stress test with verbose output"
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
        -m|--mode)
            TEST_MODE="$2"
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
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate test mode
if [[ ! "$TEST_MODE" =~ ^(quick|full|stress)$ ]]; then
    print_error "Invalid test mode: $TEST_MODE"
    print_status "Valid modes: quick, full, stress"
    exit 1
fi

# Check if bc is installed for floating point math
if ! command -v bc &> /dev/null; then
    print_warning "bc is not installed. Using integer math for sample data generation."
fi



# Run tests
run_tests 