# =============================================================================
# S3 Module cho Raw Data Storage - Free Tier Optimized
# =============================================================================

# S3 Bucket cho raw data
resource "aws_s3_bucket" "raw_data" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name = "${var.project_name}-raw-data-bucket-${var.environment}"
  })
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration - Free Tier Optimized
resource "aws_s3_bucket_lifecycle_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    id     = "aggressive_transition"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 7    # Giảm từ 30 xuống 7 ngày để tiết kiệm
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30   # Giảm từ 90 xuống 30 ngày
      storage_class = "GLACIER"
    }

    transition {
      days          = 90   # Giảm từ 365 xuống 90 ngày
      storage_class = "DEEP_ARCHIVE"
    }

    # Xóa data sau 180 ngày để tiết kiệm storage
    expiration {
      days = 180
    }
  }

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_transition {
      noncurrent_days = 7    # Giảm từ 30 xuống 7 ngày
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30   # Giảm từ 90 xuống 30 ngày
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90   # Giảm từ 2555 xuống 90 ngày
    }
  }
}

# Bucket policy cho IoT Core
resource "aws_s3_bucket_policy" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIoTCoreAccess"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.raw_data.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source
data "aws_caller_identity" "current" {} 