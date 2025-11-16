# Development S3 Bucket Example - Basic usage

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

module "development_bucket" {
  source = "../../"

  name               = var.bucket_name
  environment        = var.environment
  versioning_enabled = var.versioning_enabled

  tags = var.tags
}