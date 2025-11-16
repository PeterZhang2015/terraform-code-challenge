output "bucket_name" {
  description = "The name of the created S3 bucket"
  value       = module.production_bucket.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = module.production_bucket.bucket_arn
}

output "kms_key_id" {
  description = "The KMS key ID used for encryption"
  value       = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.s3_key[0].key_id
}