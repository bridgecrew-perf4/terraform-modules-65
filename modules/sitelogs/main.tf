terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = var.bucket_name
  acl           = "log-delivery-write"
  force_destroy = false
  tags = {
    Name      = var.bucket_name
    Project   = var.base_name
    ManagedBy = "terraform"
  }
}
