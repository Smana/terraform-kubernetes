module "bastion" {
  source = "./modules/bastion"

  name = var.bastion.name

  region     = var.global.region
  subnet_ids = module.vpc.public_subnets

  keypair_name = aws_key_pair.keypair.key_name

  autoscaling = var.bastion.autoscaling

  tags = var.tags
}
