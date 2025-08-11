###############################
# CI/CD: CodePipeline for Lambda deploy
###############################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  artifact_bucket_name = coalesce(var.artifact_bucket_name, "${var.project_name}-cicd-artifacts-${var.environment}")
  pipeline_name        = coalesce(var.pipeline_name, "${var.project_name}-lambda-cicd-${var.environment}")
  codebuild_name       = coalesce(var.codebuild_project_name, "${var.project_name}-lambda-build-${var.environment}")
}

# S3 artifact bucket for CodePipeline
resource "aws_s3_bucket" "artifacts" {
  bucket = local.artifact_bucket_name
  force_destroy = false

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM role for CodePipeline
data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${local.pipeline_name}-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    sid     = "S3Access"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*"
    ]
  }

  statement {
    sid     = "CodeBuildAccess"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetProjects"
    ]
    resources = [aws_codebuild_project.build.arn]
  }

  statement {
    sid     = "CodeStarConnectionUse"
    actions = [
      "codestar-connections:UseConnection"
    ]
    resources = [aws_codestarconnections_connection.github.arn]
  }
}

resource "aws_iam_role_policy" "codepipeline_inline" {
  name   = "${local.pipeline_name}-policy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

# IAM role for CodeBuild (grant admin for simplicity; consider least-privilege later)
data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.codebuild_name}-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "codebuild_admin" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CodeStar connection to GitHub (requires manual authorization once)
resource "aws_codestarconnections_connection" "github" {
  name          = var.codestar_connection_name
  provider_type = "GitHub"
}

# CodeBuild project
resource "aws_codebuild_project" "build" {
  name         = local.codebuild_name
  service_role = aws_iam_role.codebuild.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    environment_variable {
      name  = "TF_IN_AUTOMATION"
      value = "true"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = coalesce(var.buildspec_override, local.default_buildspec)
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${local.codebuild_name}"
      stream_name = "build"
      status      = "ENABLED"
    }
  }
  tags = var.tags
}

# Default buildspec (used by pipeline when not overridden)
locals {
  default_buildspec = <<EOF
version: 0.2
env:
  variables:
    TF_IN_AUTOMATION: "true"
phases:
  install:
    runtime-versions:
      python: 3.11
    commands:
      - echo Installing Terraform
      - curl -sSL https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip -o /tmp/terraform.zip
      - unzip -o /tmp/terraform.zip -d /usr/local/bin
      - terraform version
  build:
    commands:
      - echo Applying Terraform in ${var.terraform_workdir}
      - cd ${var.terraform_workdir}
      - terraform init -input=false
      - terraform plan -input=false -no-color
      - terraform apply -auto-approve -input=false -no-color
artifacts:
  files:
    - '**/*'
EOF
}

# CodePipeline definition
resource "aws_codepipeline" "this" {
  name     = local.pipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId  = "${var.github_owner}/${var.github_repo}"
        BranchName        = var.github_branch
        DetectChanges     = "false"
      }
    }
  }

  stage {
    name = "BuildAndDeploy"
    action {
      name            = "CodeBuild"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build.name
        PrimarySource = "source_output"
        EnvironmentVariables = jsonencode([
          { name = "TF_IN_AUTOMATION", value = "true", type = "PLAINTEXT" }
        ])
      }
    }
  }

  tags = var.tags
}


