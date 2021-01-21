module "kubernetes" {
  source = "./modules/kubernetes"

  region = var.global.region
  zones  = var.global.zones

  keypair_name = aws_key_pair.keypair.key_name
  bastion_host = module.bastion.bastion_cname_dns
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

  etcd_client_cert       = module.etcd.tls_certs[format("%s-etcd-client.%s", var.global.namespace, var.hosted_zone)]
  etcd_client_key        = module.etcd.tls_keys[format("%s-etcd-client.%s", var.global.namespace, var.hosted_zone)]
  etcd_ca_cert           = module.etcd.ca_cert_pem
  etcd_ips               = module.etcd.etcd_ips
  etcd_security_group_id = module.etcd.etcd_security_group_id

  tags = var.tags
}
