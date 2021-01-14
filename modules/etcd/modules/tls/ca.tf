/* Generate a CA cert */
resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = var.ca.common_name
    organization = var.ca.organization
  }

  allowed_uses = [
    "key_encipherment",
    "cert_signing",
    "server_auth",
    "client_auth",
  ]

  validity_period_hours = var.ca.validity_period_hours
  early_renewal_hours   = var.ca.early_renewal_hours
  is_ca_certificate     = true
}

resource "aws_s3_bucket_object" "ca_cert" {
  bucket     = aws_s3_bucket.tls_store.bucket
  key        = "ca.pem"
  content    = tls_self_signed_cert.ca.cert_pem
  kms_key_id = aws_kms_key.tls_store_s3_kms.arn
}

resource "aws_s3_bucket_object" "ca_key" {
  bucket     = aws_s3_bucket.tls_store.bucket
  key        = "ca.key"
  content    = tls_private_key.ca.private_key_pem
  kms_key_id = aws_kms_key.tls_store_s3_kms.arn
}
