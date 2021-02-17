terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  alias = "us_east_1"
}

data "aws_route53_zone" "main" {
  name         = var.domain
  private_zone = false
}

data "aws_s3_bucket" "logs" {
  bucket = var.logbucket
}
