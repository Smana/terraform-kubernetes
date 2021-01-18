output "etcd_ips" {
  description = "Etcd members private IP addresses"
  value       = data.aws_instances.etcd.private_ips
}

# output "tls_certs" {
#   value = module.tls.tls_certs
#   # sensitive = true
# }

# output "tls_keys" {
#   value = module.tls.tls_keys
#   # sensitive = true
# }
