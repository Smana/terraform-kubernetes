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
      instance_type = string
      subnet_id     = string
    })
    worker = object({
      instance_type = string
      subnet_ids    = list(string)
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
      subnet_id     = null
    }
    worker = {
      instance_type = "t2.medium"
      subnet_ids    = []
    }
    autoscaling = {
      min  = 1
      max  = 3
      tags = []
    }
  }
}
