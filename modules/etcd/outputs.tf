output "etcd_ips" {
  description = "Etcd members private IP addresses"
  value       = data.aws_instances.etcd.private_ips
}

output "certificates" {
  value     = module.tls.certificates
  sensitive = true
}
