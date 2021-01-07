output "bastion_cname_dns" {
  description = "Domain name Alias to connect to the bastion instances"
  value       = aws_route53_record.bastion.fqdn
}

output "bastion_elb_dns" {
  description = "ELB Domain name used to connect to the bastion instances"
  value       = aws_elb.bastion.dns_name
}
