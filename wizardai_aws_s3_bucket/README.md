# Wizard.AI AWS S3 Bucket Module

This Terraform module creates an AWS S3 bucket that enforces Wizard.AI's organizational policies and security best practices.

## Features

- **Enforced Naming Convention**: Automatically applies the `wizardai-<name>-<environment>` naming pattern
- **Encryption at Rest**: Server-side encryption enabled by default (AES256 or KMS)
- **Encryption in Transit**: HTTPS-only access enforced via bucket policy
- **Security Defaults**: Public access blocked by default
- **Versioning**: Optional versioning support (enabled by default)
- **Lifecycle Management**: Optional lifecycle rules for cost optimization

## Usage

### Basic Usage

```hcl
module "my_bucket" {
  source = "github.com/PeterZhang2015/terraform-code-challenge//wizardai_aws_s3_bucket?ref=v0.0.1"
  
  name        = "my-app-data"
  environment = "development"
}
```

### Local Development

```hcl
module "my_bucket" {
  source = "./wizardai_aws_s3_bucket"
  
  name        = "my-app-data"
  environment = "development"
}
```

### Advanced Usage with KMS Encryption

```hcl
module "my_secure_bucket" {
  source = "github.com/PeterZhang2015/terraform-code-challenge//wizardai_aws_s3_bucket?ref=v0.0.1"
  
  name        = "sensitive-data"
  environment = "production"
  kms_key_id  = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  lifecycle_rules = [
    {
      id     = "delete_old_versions"
      status = "Enabled"
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]
  
  tags = {
    Team    = "data-engineering"
    Project = "analytics"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.1 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the S3 bucket (will be prefixed with 'wizardai-' and suffixed with environment) | `string` | n/a | yes |
| environment | The environment (development, staging, production) | `string` | n/a | yes |
| versioning_enabled | Enable versioning for the S3 bucket | `bool` | `true` | no |
| kms_key_id | The KMS key ID to use for server-side encryption. If not provided, AES256 encryption will be used. | `string` | `null` | no |
| lifecycle_rules | List of lifecycle rules for the bucket | `list(object)` | `null` | no |
| tags | Additional tags to apply to the bucket | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The ID of the S3 bucket |
| bucket_arn | The ARN of the S3 bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |
| bucket_hosted_zone_id | The Route 53 Hosted Zone ID for this bucket's region |
| bucket_region | The AWS region this bucket resides in |

## Security Features

### Encryption at Rest
- Server-side encryption is enforced by default
- Supports both AES256 (default) and KMS encryption
- KMS encryption includes bucket key optimization when KMS is used

### Encryption in Transit
- HTTPS-only access enforced via bucket policy
- All HTTP requests are denied

### Public Access Prevention
- All public access is blocked by default
- Cannot be overridden without modifying the module

### Naming Convention
- Enforces the `wizardai-<name>-<environment>` pattern
- Validates bucket name format to ensure compliance with S3 naming rules

## Examples

See the `examples/` directory for complete usage examples for different environments and use cases.