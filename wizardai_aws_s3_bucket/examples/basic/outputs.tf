output "bucket_name" {
  description = "The name of the created S3 bucket"
  value       = module.development_bucket.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = module.development_bucket.bucket_arn
}