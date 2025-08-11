output "pipeline_name" {
  value       = aws_codepipeline.this.name
  description = "Name of the CodePipeline"
}

output "artifact_bucket" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "Artifact bucket name"
}

output "codebuild_project_name" {
  value       = aws_codebuild_project.build.name
  description = "CodeBuild project name"
}

output "codestar_connection_arn" {
  value       = aws_codestarconnections_connection.github.arn
  description = "CodeStar connection ARN"
}


