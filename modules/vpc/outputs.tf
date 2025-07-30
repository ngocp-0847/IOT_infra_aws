# =============================================================================
# Outputs cho VPC Module
# =============================================================================

output "vpc_id" {
  description = "ID của VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block của VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs của public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs của private subnets"
  value       = aws_subnet.private[*].id
}

output "lambda_security_group_id" {
  description = "ID của security group cho Lambda"
  value       = aws_security_group.lambda.id
}

output "internet_gateway_id" {
  description = "ID của Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs của NAT Gateways"
  value       = aws_nat_gateway.main[*].id
} 