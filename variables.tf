variable "global" {
  default = {
    environment = "dev"
    region      = "eu-west-3"
    zones       = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
  }
}

variable "network" {
  default = {
    vpc_name = "cloud-native-vpc"
    vpc_cidr = "10.0.0.0/16"
  }
}
