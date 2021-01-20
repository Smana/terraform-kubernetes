variable "region" {
  description = "Name of the AWS Region"
  default     = "eu-west-3"
}

variable "zones" {
  description = "List of zones where the workers are created"
  type        = list(string)
}

variable "keypair_name" {
  description = "AWS keypair used for instances"
  type        = string
}

variable "ssh_user" {
  description = "Username for SSH connections through the bastion"
  default     = "ubuntu"
}

variable "bastion_host" {
  description = "Bastion Host"
}

variable "hosted_zone" {
  description = "Hosted zone to be used for the alias"
}

variable "tags" {
  description = "Default tags for all the resources"
  type        = map(string)
}

variable "allowed_ingress_cidr" {
  default = {
    ssh = []
    api = []
  }
}

variable "public_subnets" {
  description = ""
  type        = list(string)
}

variable "private_subnets" {
  description = ""
  type        = list(string)
}

variable "cluster" {
  description = "Kubernetes configuration"
  type = object({
    name = string
    control_plane = object({
      count         = number
      instance_type = string
    })
    worker = object({
      instance_type = string
    })
    autoscaling = object({
      min  = number
      max  = number
      tags = list(any)
    })
  })
  default = {
    name = null
    control_plane = {
      instance_type = "t2.medium"
      count         = 1
    }
    worker = {
      instance_type = "t2.medium"
    }
    autoscaling = {
      min  = 1
      max  = 3
      tags = []
    }
  }
}

variable "etcd_client_cert" {
  description = "TLS client cert for external Etcd"
  type        = string
}

variable "etcd_client_key" {
  description = "TLS key for external Etcd"
  type        = string
}
variable "etcd_ca_cert" {
  description = "Etcd CA certificate"
  type        = string
}
variable "etcd_ips" {
  description = "Etcd IP addresses"
  type        = string
}

variable "etcd_security_group_id" {
  description = "Etcd security group ID"
  type        = string
}
