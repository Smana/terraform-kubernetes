module "etcd" {
  source    = "./modules/etcd"
  namespace = var.global.namespace
  stage     = var.global.stage

  members_count = var.etcd.members_count
  instance_type = var.etcd.instance_type

  region     = var.global.region
  zones      = var.global.zones
  subnet_ids = module.vpc.public_subnets

  bastion_host = module.bastion.bastion_cname_dns
  hosted_zone  = var.hosted_zone

  allowed_ingress_cidr = var.vpc.private_subnets

  keypair_name = aws_key_pair.keypair.key_name

  tls = {
    ca_common_name              = "Kubeadm"
    ca_organization             = "Smana"
    ca_early_renewal_hours      = 17520
    ca_validity_period_hours    = 360
    certs_early_renewal_hours   = 17520
    certs_validity_period_hours = 360
  }

  tags = var.tags
}
