output "ssh_user" {
  description = "SSH user to download kubeconfig file"
  value       = "ubuntu"
}

output "api_dns" {
  description = "Kubernetes API Load Balancer domain name"
  value       = aws_route53_record.k8s-api.fqdn
}
output "control-plane_private_ips" {
  description = "Control plane instances private IP addresses"
  value       = data.aws_instances.control-plane.private_ips
}

output "kubeconfig_local_path" {
  description = "Path where the Kubernetes config is stored"
  value       = local.kubeconfig_local_path
}
