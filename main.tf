provider "aws" {
  region = var.global.region
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


/* Keypair */
resource "aws_key_pair" "keypair" {
  key_name   = var.keypair_name
  public_key = file(var.ssh_public_key)
}
