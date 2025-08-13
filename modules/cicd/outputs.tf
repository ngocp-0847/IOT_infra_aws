output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role for GitHub Actions"
}

output "github_actions_role_name" {
  value       = aws_iam_role.github_actions.name
  description = "Name of the IAM role for GitHub Actions"
}

output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "ARN of the GitHub OIDC provider"
}