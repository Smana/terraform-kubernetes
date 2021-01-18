output "bucket_arn" {
  value       = aws_s3_bucket.tls_store.arn
  description = "ARN of the created bucket"
}

output "bucket_name" {
  value       = format("%s-%s", module.label.id, var.bucket_name)
  description = "Name of the created bucket"
}

output "kms_key_arn" {
  value       = aws_kms_key.tls_store_s3_kms.arn
  description = "ARN of the CMK KMS key used for encryption S3 bucket data at rest"
}

output "kms_key_alias_arn" {
  value       = aws_kms_alias.tls_store_s3_kms.arn
  description = "ARN of the CMK KMS key alias"
}

output "kms_key_alias_name" {
  value       = aws_kms_alias.tls_store_s3_kms.name
  description = "Name of the CMK KMS key alias"
}

output "s3_read_policy_arn" {
  value       = aws_iam_policy.tls_store_s3_read.arn
  description = "ARN of the IAM role that provides read access to the created S3 bucket"
}

output "s3_admin_policy_arn" {
  value       = aws_iam_policy.tls_store_s3_admin.arn
  description = "ARN of the IAM role that provides admin access to the created S3 bucket"
}

output "ca_cert_pem" {
  value = tls_self_signed_cert.ca.cert_pem
}

output "ca_private_key_pem" {
  value     = tls_private_key.ca.private_key_pem
  sensitive = true
}

output "tls_certs" {
  description = "TLS certificates for etcd members"
  value = {
    for idx, cert in var.certs :
    cert.common_name => tls_locally_signed_cert.certs[idx].cert_pem
  }
}

output "tls_keys" {
  description = "TLS keys for etcd members"
  value = {
    for idx, cert in var.certs :
    cert.common_name => tls_private_key.certs[idx].private_key_pem
  }
  sensitive = true
}
