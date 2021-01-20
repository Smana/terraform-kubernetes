output "etcd_ips" {
  description = "Etcd members private IP addresses"
  value       = data.aws_instances.etcd.private_ips
}

output "etcd_security_group_id" {
  description = "Etcd security group"
  value       = aws_security_group.etcd.id
}

output "ca_cert_pem" {
  value = module.tls.ca_cert_pem
}

output "ca_private_key_pem" {
  value     = module.tls.ca_private_key_pem
  sensitive = true
}

output "tls_certs" {
  value = module.tls.tls_certs
}
output "tls_keys" {
  value     = module.tls.tls_keys
  sensitive = true
}
