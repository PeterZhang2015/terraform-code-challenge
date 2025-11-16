# Example terraform.tfvars for production environment
# Copy this file to terraform.tfvars and customize the values

# AWS region to deploy resources
aws_region = "us-west-2"

# Bucket configuration
bucket_name = "critical-data"
environment = "production"

# Security configuration
versioning_enabled = true

# Optional: KMS key for encryption (if not using the one created in main.tf)
# kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

# Optional: Lifecycle rules for cost optimization
lifecycle_rules = [
   {
     id     = "transition_to_ia"
     status = "Enabled"
     expiration = {
       days = 365
     }
   },
   {
     id     = "cleanup_old_versions"
     status = "Enabled"
     noncurrent_version_expiration = {
       noncurrent_days = 30
     }
   }
 ]

# Tags for production environment
tags = {
  Team        = "data-platform"
  Project     = "analytics"
  Criticality = "high"
  Compliance  = "required"
  Owner       = "data-team@wizardai.com"
  Environment = "production"
}