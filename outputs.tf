
# Key pair name
output "keypair_name" {
  description = "AWS keypair used for instances"
  value       = aws_key_pair.keypair.key_name
}

# Etcd IP addresses
output "etcd_ips" {
  description = "Etcd members private IP addresses"
  value       = module.etcd.etcd_ips
}

# Kubernetes API DNS
# output "api_dns" {
#   description = "Kubernetes API Load Balancer domain name"
#   value       = module.kubernetes.api_dns
# }

# Bastion DNS
output "bastion_host" {
  description = "Bastion Load Balancer domain name"
  value       = module.bastion.bastion_cname_dns
}

# # Control plane IP addresses
# output "control_plane_ips" {
#   description = "Control plane IP addresses"
#   value       = module.kubernetes.control_plane_ips
# }

# # Kubeconfig generated locally after the cluster provisionning
# output "kubeconfig" {
#   description = "Local kubeconfig path"
#   value       = module.kubernetes.kubeconfig_local_path
# }

output "certificates" {
  value     = module.tls.certificates
  sensitive = true
}
