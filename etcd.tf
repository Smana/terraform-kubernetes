module "etcd" {
  source        = "./modules/etcd"
  name          = var.etcd.name
  members_count = var.etcd.members_count
  instance_type = var.etcd.instance_type

  region     = var.global.region
  zones      = var.global.zones
  subnet_ids = module.vpc.public_subnets

  bastion_host = module.bastion.bastion_cname_dns

  keypair_name = aws_key_pair.keypair.key_name

  tags = var.tags
}
