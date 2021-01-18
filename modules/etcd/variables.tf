variable "namespace" {
  description = "Namespace which could be your organization name or an abbreviation"
  type        = string
  default     = null
}
variable "stage" {
  description = "Stage, e.g. 'prod', 'staging', 'dev'"
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

variable "bastion_host" {
  description = "Bastion Host"
}

variable "ssh_user" {
  description = "Username for SSH connections through the bastion"
  default     = "ubuntu"
}

variable "hosted_zone" {
  description = "Hosted zone to be used for the alias"
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
  description = "AWS instance type"
  type        = string
  default     = "m4.large"
}

variable "tls" {
  description = "Settings used to generate TLS certificates"
  type = object({
    ca_common_name              = string
    ca_organization             = string
    ca_validity_period_hours    = number
    ca_early_renewal_hours      = number
    certs_validity_period_hours = number
    certs_early_renewal_hours   = number
  })
  default = {
    ca_common_name              = "Etcd CA"
    ca_organization             = "Corp"
    ca_validity_period_hours    = 17520
    ca_early_renewal_hours      = 360
    certs_validity_period_hours = 17520
    certs_early_renewal_hours   = 360
  }
}

variable "ca_cert_pem" {
  description = "value"
  type        = string
  default     = null
}

variable "tls_certs" {
  description = "value"
  type        = map(any)
  default     = {}
}

variable "tls_keys" {
  description = "value"
  type        = map(any)
  default     = {}
}
