```
global = {
    environment = "dev"
    region      = "eu-west-3"
    zones       = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}

keypair_name = "smana"

hosted_zone = "cloud.smana.me"

tags = {}

cluster = {
    name = "k8s-smana"
    control_plane = {
      instance_type = "t2.medium"
    }
    worker = {
      instance_type = "t2.medium"
    }
    autoscaling = {
        max = 1
        min = 3
        tags = [
        {
          key                 = "Application"
          value               = "Kubernetes"
          propagate_at_launch = true
        }
      ]
    }
}

vpc = {
    vpc_name = "myvpc"
    vpc_cidr        = "10.0.0.0/16"
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

bastion = {
  name = "smana"
  autoscaling = {
    min = 1
    max = 2
    tags = [
      {
        key = "Application"
        value = "Kubernetes"
      }
    ]
  }
}
```