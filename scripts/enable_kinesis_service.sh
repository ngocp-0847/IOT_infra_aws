#!/bin/bash

# =============================================================================
# Enable Kinesis Service for IoT Platform
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

print_info "Kinesis Service Subscription Required"
echo "=========================================="
echo ""
print_info "The Kinesis service requires a subscription in some AWS regions."
print_info "Please follow these steps to enable Kinesis:"
echo ""
print_info "1. Go to AWS Console: https://console.aws.amazon.com/"
print_info "2. Navigate to Kinesis Data Streams"
print_info "3. If prompted, click 'Subscribe' or 'Enable'"
print_info "4. Wait for the subscription to be activated"
echo ""
print_info "Alternative: Try using a different region that has Kinesis enabled by default:"
print_info "  - us-east-1 (N. Virginia)"
print_info "  - us-west-2 (Oregon)"
print_info "  - eu-west-1 (Ireland)"
echo ""
print_info "To change region, update your terraform.tfvars:"
print_info "  aws_region = \"us-east-1\""
echo ""
print_info "Then run:"
print_info "  terraform plan"
print_info "  terraform apply"
echo ""
print_warning "Note: Kinesis is part of AWS Free Tier but may require explicit subscription in some regions." 