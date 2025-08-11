variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "artifact_bucket_name" {
  type        = string
  description = "Optional S3 bucket name for CodePipeline artifacts"
  default     = null
}

variable "pipeline_name" {
  type        = string
  description = "Optional CodePipeline name"
  default     = null
}

variable "codebuild_project_name" {
  type        = string
  description = "Optional CodeBuild project name"
  default     = null
}

variable "codestar_connection_name" {
  type        = string
  description = "CodeStar connection name to create (you will need to authorize it in console)"
}

variable "github_owner" {
  type        = string
  description = "GitHub owner/org"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch to track (e.g., main)"
  default     = "main"
}

variable "terraform_workdir" {
  type        = string
  description = "Relative path to Terraform working directory for apply (e.g., environments/dev)"
  default     = "environments/dev"
}

variable "buildspec_override" {
  type        = string
  description = "Inline buildspec YAML override (optional)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}


