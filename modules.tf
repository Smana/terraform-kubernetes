module "vpc" {
  source = "git@github.com:Smana/terraform-aws-vpc.git"

  aws_region      = "eu-west-3"
  aws_zones       = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
  vpc_name        = "cloud-native-vpc"
  vpc_cidr        = "10.0.0.0/16"
  private_subnets = "true"

  ## Tags
  tags = {
    env   = "dev"
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

/*
module "kubernetes" {
  source = "scholzj/kubernetes/aws"

  aws_region           = "eu-west-3"
  cluster_name         = "smana"
  master_instance_type = "t2.medium"
  worker_instance_type = "t2.medium"
  ssh_public_key       = "~/.ssh/id_rsa.pub"
  ssh_access_cidr      = ["0.0.0.0/0"]
  api_access_cidr      = ["0.0.0.0/0"]
  min_worker_count     = 1
  max_worker_count     = 3
  hosted_zone          = "smana.me"
  hosted_zone_private  = false

  master_subnet_id  = element(module.vpc.private_subnet_ids, 0)
  worker_subnet_ids = module.vpc.private_subnet_ids

  # Tags
  tags = {
    Application = "AWS-Kubernetes"
  }

  # Tags in a different format for Auto Scaling Group
  tags2 = [
    {
      key                 = "Application"
      value               = "AWS-Kubernetes"
      propagate_at_launch = true
    },
  ]

  addons = []
}
*/
