
resource "tls_private_key" "certs" {
  for_each  = { for idx, cert in var.certs : idx => cert }
  algorithm = "RSA"
}

resource "tls_cert_request" "certs" {
  for_each        = { for idx, cert in var.certs : idx => cert }
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.certs[each.key].private_key_pem
  ip_addresses    = each.value.ip_addresses
  uris            = each.value.uris
  dns_names       = each.value.dns_names

  subject {
    common_name  = each.value.common_name
    organization = var.ca.organization
  }
}

resource "tls_locally_signed_cert" "certs" {
  for_each              = { for idx, cert in var.certs : idx => cert }
  cert_request_pem      = tls_cert_request.certs[each.key].cert_request_pem
  ca_key_algorithm      = "RSA"
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = each.value.validity_period_hours
  early_renewal_hours   = each.value.early_renewal_hours
  allowed_uses          = each.value.allowed_uses
}

resource "aws_s3_bucket_object" "tls_cert" {
  for_each   = { for idx, cert in var.certs : idx => cert }
  bucket     = aws_s3_bucket.tls_store.bucket
  key        = format("%s_%s_cert.pem", each.key, each.value.common_name)
  content    = tls_locally_signed_cert.certs[each.key].cert_pem
  kms_key_id = aws_kms_key.tls_store_s3_kms.arn
}

resource "aws_s3_bucket_object" "tls_key" {
  for_each   = { for idx, cert in var.certs : idx => cert }
  bucket     = aws_s3_bucket.tls_store.bucket
  key        = format("%s_%s_key.pem", each.key, each.value.common_name)
  content    = tls_private_key.certs[each.key].private_key_pem
  kms_key_id = aws_kms_key.tls_store_s3_kms.arn
}
