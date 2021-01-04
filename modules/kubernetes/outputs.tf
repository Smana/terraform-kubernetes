output "ssh_user" {
  description = "SSH user to download kubeconfig file"
  value       = "ubuntu"
}

output "api_dns" {
  description = "Kubernetes API Load Balancer domain name"
  value       = aws_route53_record.k8s-api.fqdn
}
output "control-plane-0-id" {
  description = "ID of the first control-plane"
  value       = data.aws_instances.control-plane-0.ids[0]
}
