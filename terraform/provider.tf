provider "aws" {
  version = "~> 2.57"
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}