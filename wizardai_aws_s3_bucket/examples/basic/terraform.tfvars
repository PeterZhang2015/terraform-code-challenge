# Development terraform.tfvars
# Actual values for development environment

# AWS region to deploy resources
aws_region = "us-west-2"

# Bucket configuration
bucket_name = "my-app-logs"
environment = "development"

# Tags
tags = {
  Team    = "backend"
  Project = "my-app"
  Owner   = "john.doe@wizardai.com"
}