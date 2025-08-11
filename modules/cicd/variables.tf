variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "github_owner" {
  type        = string
  description = "GitHub owner/org"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}