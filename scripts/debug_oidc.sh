#!/bin/bash

# =============================================================================
# Script Debug OIDC cho GitHub Actions
# =============================================================================
# Script này giúp debug và kiểm tra cấu hình OIDC để khắc phục lỗi:
# "Not authorized to perform sts:AssumeRoleWithWebIdentity"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  DEBUG OIDC CONFIGURATION${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_status "ERROR" "terraform.tfvars not found!"
    echo "Please create terraform.tfvars from terraform.tfvars.example"
    exit 1
fi

# Extract values from terraform.tfvars
PROJECT_NAME=$(grep 'project_name' terraform.tfvars | cut -d'"' -f2)
ENVIRONMENT=$(grep 'environment' terraform.tfvars | cut -d'"' -f2)
AWS_REGION=$(grep 'aws_region' terraform.tfvars | cut -d'"' -f2)
GITHUB_OWNER=$(grep 'github_owner' terraform.tfvars | cut -d'"' -f2)
GITHUB_REPO=$(grep 'github_repo' terraform.tfvars | cut -d'"' -f2)

print_status "INFO" "Reading terraform.tfvars configuration..."
echo "  PROJECT_NAME: $PROJECT_NAME"
echo "  ENVIRONMENT: $ENVIRONMENT"
echo "  AWS_REGION: $AWS_REGION"
echo "  GITHUB_OWNER: $GITHUB_OWNER"
echo "  GITHUB_REPO: $GITHUB_REPO"
echo

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    print_status "ERROR" "AWS CLI not found! Please install AWS CLI"
    exit 1
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$AWS_ACCOUNT_ID" ]; then
    print_status "ERROR" "Cannot get AWS Account ID. Please configure AWS credentials"
    exit 1
fi

print_status "OK" "AWS Account ID: $AWS_ACCOUNT_ID"

# Construct expected role name
EXPECTED_ROLE_NAME="${PROJECT_NAME}-github-actions-${ENVIRONMENT}"
EXPECTED_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EXPECTED_ROLE_NAME}"

print_status "INFO" "Expected IAM Role ARN: $EXPECTED_ROLE_ARN"

# Check if IAM role exists
echo
print_status "INFO" "Checking if IAM role exists..."
if aws iam get-role --role-name "$EXPECTED_ROLE_NAME" &>/dev/null; then
    print_status "OK" "IAM Role exists: $EXPECTED_ROLE_NAME"
    
    # Get role trust policy
    echo
    print_status "INFO" "Checking role trust policy..."
    TRUST_POLICY=$(aws iam get-role --role-name "$EXPECTED_ROLE_NAME" --query 'Role.AssumeRolePolicyDocument' --output json)
    echo "$TRUST_POLICY" | jq .
    
    # Check OIDC provider
    echo
    print_status "INFO" "Checking OIDC provider..."
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" &>/dev/null; then
        print_status "OK" "OIDC Provider exists"
    else
        print_status "ERROR" "OIDC Provider not found!"
        echo "Run 'terraform apply' to create the OIDC provider"
    fi
    
else
    print_status "ERROR" "IAM Role not found: $EXPECTED_ROLE_NAME"
    echo "This is likely the cause of the OIDC error!"
    echo
    print_status "INFO" "Solutions:"
    echo "1. Run 'terraform apply' to create the IAM role"
    echo "2. Or check if project_name in terraform.tfvars matches GitHub environment variables"
fi

echo
print_status "INFO" "GitHub Environment Variables Required:"
echo "  PROJECT_NAME: $PROJECT_NAME"
echo "  ENVIRONMENT: $ENVIRONMENT"
echo "  AWS_REGION: $AWS_REGION (optional, defaults to us-east-1)"
echo "  AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID (optional, but recommended)"

echo
print_status "INFO" "GitHub Actions workflow should assume role:"
echo "  $EXPECTED_ROLE_ARN"

echo
print_status "INFO" "Next steps:"
echo "1. Verify GitHub environment variables match terraform.tfvars"
echo "2. Ensure IAM role exists by running 'terraform apply'"
echo "3. Check that workflow is running from correct branch/environment"
echo "4. Verify OIDC provider thumbprints are up to date"

echo
print_status "INFO" "Debug completed!"
