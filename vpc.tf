module "vpc" {
  source = "git@github.com:Smana/terraform-aws-vpc.git"

  aws_region      = var.global.region
  aws_zones       = var.global.zones
  vpc_name        = var.network.vpc_name
  vpc_cidr        = var.network.vpc_cidr
  private_subnets = "true"

  ## Tags
  tags = {
    env   = var.global.env
    owner = "smana"
  }
}

output "vpc" {
  value = module.vpc.vpc_id
}

output "subnets" {
  value = module.vpc.subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}
