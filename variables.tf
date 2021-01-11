variable "hosted_zone" {
  description = "Hosted zone to be used for the alias"
}

variable "ssh_public_key" {
  description = "Path to the pulic part of SSH key which should be used for the instance"
  default     = "~/.ssh/id_rsa.pub"
}

variable "keypair_name" {
  description = "TODO"
  type        = string
}

variable "global" {
  description = "Global values to identify the environment, location and tag resources"
  type = object({
    environment = string
    region      = string
    zones       = list(string)
  })
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = object({})
}

variable "vpc" {
  description = "VPC configuration, subnet details"
  type = object({
    vpc_name        = string
    vpc_cidr        = string
    private_subnets = list(string)
    public_subnets  = list(string)
  })
  default = {
    vpc_name        = null
    vpc_cidr        = "10.0.0.0/16"
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  }
}

variable "cluster" {
  description = "TODO"
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
      count         = 1
      instance_type = "t2.medium"
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

variable "bastion" {
  description = "value"
  type = object({
    name = string
    autoscaling = object({
      min  = number
      max  = number
      tags = list(any)
    })
  })
}

variable "etcd" {
  type = object({
    name          = string
    members_count = number
    instance_type = string
  })
}
