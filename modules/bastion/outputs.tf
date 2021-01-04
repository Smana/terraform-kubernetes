output "bastion_fqdn" {
  description = "Domain name used to connect to the bastion instances"
  value       = aws_route53_record.bastion.fqdn
}
