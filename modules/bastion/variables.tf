variable "name" {
  description = "Prefix for the bastion autoscaling group"
  type        = string
  default     = null
}


variable "region" {
  description = "Name of the AWS Region"
  default     = "eu-west-3"
}

variable "tags" {
  description = "Default tags for all the resources"
  type        = map(string)
}

variable "keypair_name" {
  description = "TODO"
  type        = string
}

variable "hosted_zone" {
  description = "Hosted zone to be used for the alias"
}

variable "subnet_ids" {
  description = "value"
  type        = list(string)
}

variable "instance_type" {
  description = "value"
  type        = string
  default     = "t2.medium"
}

variable "autoscaling" {
  description = "value"
  type = object({
    min  = number
    max  = number
    tags = list(any)
  })
  default = {
    min  = 1
    max  = 2
    tags = []
  }
}
