provider "aws" {
  region = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket = "cloudsante-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
    workspace_key_prefix = "project"
  }
}

