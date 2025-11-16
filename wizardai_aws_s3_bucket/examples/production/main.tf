# Production S3 Bucket Example with KMS encryption and lifecycle rules

terraform {
  required_version = ">= 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# KMS key for encryption (only created if external key not provided)
resource "aws_kms_key" "s3_key" {
  count                   = var.kms_key_id == null ? 1 : 0
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name        = "s3-encryption-key"
    Environment = var.environment
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  count         = var.kms_key_id == null ? 1 : 0
  name          = "alias/s3-encryption-key-${var.bucket_name}"
  target_key_id = aws_kms_key.s3_key[0].key_id
}

module "production_bucket" {
  source = "../../"

  name               = var.bucket_name
  environment        = var.environment
  versioning_enabled = var.versioning_enabled
  kms_key_id         = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.s3_key[0].arn

  lifecycle_rules = var.lifecycle_rules != null ? var.lifecycle_rules : tolist([
    {
      id     = "transition_to_ia"
      status = "Enabled"
      expiration = {
        days = 365
      }
      noncurrent_version_expiration = null
    },
    {
      id     = "cleanup_old_versions"
      status = "Enabled"
      expiration = null
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ])

  tags = var.tags
}