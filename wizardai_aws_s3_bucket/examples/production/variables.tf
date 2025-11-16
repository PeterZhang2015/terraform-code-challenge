variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "Name for the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "External KMS key ID to use for encryption (optional)"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id     = string
    status = string
    expiration = optional(object({
      days = number
    }))
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
  }))
  default = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}