variable "label" {
  type = object({
    namespace = string
    name      = string
    stage     = string
  })
  default = {
    namespace = "corp"
    name      = "myTLS"
    stage     = "dev"
  }
}

variable "tags" {
  description = "Default tags for all the resources"
  type        = map(string)
}

variable "admin_role_arns" {
  description = "Amazon Resource Names for admin"
  type        = list(string)
}
variable "user_role_arns" {
  description = "Amazon Resource Names for users (Read Only)"
  type        = list(string)
}

variable "kms" {
  type = object({
    deletion_window_in_days = number
    enable_key_rotation     = bool
  })
  default = {
    deletion_window_in_days = 30
    enable_key_rotation     = false
  }
}

variable "bucket_name" {
  description = "S3 bucket name"
  default     = "mybucket"
}

variable "ca" {
  type = object({
    common_name           = string
    organization          = string
    validity_period_hours = number
    early_renewal_hours   = number
  })
  default = {
    common_name           = "foobar"
    organization          = "mycompany"
    validity_period_hours = 17520 # 3 years
    early_renewal_hours   = 360   # 15 days
  }
}

variable "certs" {
  description = "List of certificates to generate"
  type = list(object({
    common_name           = string
    ip_addresses          = list(string)
    uris                  = list(string)
    dns_names             = list(string)
    allowed_uses          = list(string)
    validity_period_hours = number
    early_renewal_hours   = number
  }))
  default = [
    {
      common_name           = "tlsexample"
      ip_addresses          = ["10.42.42.42"]
      uris                  = ["https://example.tld"]
      dns_names             = ["example.tld"]
      allowed_uses          = ["server_auth", "client_auth"]
      validity_period_hours = 17520 # 3 years
      early_renewal_hours   = 360   # 15 days
    }
  ]
}
