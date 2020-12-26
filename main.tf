provider "aws" {
  region = "eu-west-3"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.22"
    }
  }

  required_version = ">= 0.14"

  backend "s3" {
    bucket = "tfroot"
    key    = "root/"
    region = "eu-west-3"
  }
}
