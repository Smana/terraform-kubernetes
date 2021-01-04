output "ssh_user" {
  description = "SSH user to download kubeconfig file"
  value       = "ubuntu"
}

output "api_dns" {
  description = "Kubernetes API Load Balancer domain name"
  value       = aws_route53_record.k8s-api.fqdn
}
