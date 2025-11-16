# Variables for AWS S3 Bucket Module

variable "name" {
  description = "The name of the S3 bucket (will be prefixed with 'wizardai-' and suffixed with environment)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Bucket name must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "The environment (development, staging, production)"
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
  description = "The KMS key ID to use for server-side encryption. If not provided, AES256 encryption will be used."
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
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}
}