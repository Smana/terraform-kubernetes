/*
module "kubernetes" {
  source = "git@github.com:Smana/terraform-aws-kubernetes.git"

  aws_region           = var.global.region
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
    env         = var.global.env
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
