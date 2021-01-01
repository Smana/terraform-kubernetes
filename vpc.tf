module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name = var.vpc.vpc_name
  cidr = var.vpc.vpc_cidr

  azs             = var.global.zones
  private_subnets = var.vpc.private_subnets
  public_subnets  = var.vpc.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = var.global.environment
  }
}
