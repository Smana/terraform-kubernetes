variable "name" {
  description = "Prefix for the etcd cluster"
  type        = string
  default     = null
}

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

variable "tags" {
  description = "Default tags for all the resources"
  type        = map(string)
}

variable "subnet_ids" {
  description = ""
  type        = list(string)
}

variable "members_count" {
  description = "Number of members in the cluster"
  type        = string
}

variable "instance_type" {
  description = "value"
  type        = string
  default     = "m4.large"
}
