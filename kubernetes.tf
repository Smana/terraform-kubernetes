module "kubernetes" {
  source = "./modules/kubernetes"

  region = var.global.region
  zones  = var.global.zones

  keypair_name = aws_key_pair.keypair.key_name
  hosted_zone  = var.hosted_zone

  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  /* currently this is mandatory to give all the items within an object
  waiting for the 'optional' function to be available
  https://www.terraform.io/docs/configuration/types.html#experimental-optional-object-type-attributes
  */
  cluster = {
    name = var.cluster.name
    control_plane = {
      count         = var.cluster.control_plane.count
      instance_type = var.cluster.control_plane.instance_type
      subnet_id     = element(module.vpc.private_subnets, 0)
    }
    worker = {
      instance_type = var.cluster.worker.instance_type
      subnet_ids    = module.vpc.private_subnets
    }
    autoscaling = {
      min  = 1
      max  = 3
      tags = var.cluster.autoscaling.tags
    }
  }

  allowed_ingress_cidr = {
    ssh = ["0.0.0.0/0"]
    api = ["0.0.0.0/0"]
  }

  tags = var.tags
}
