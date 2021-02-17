# Terraform Modules

A collection of personal terraform modules that I use to stand up infrastructure.


## Example Usage

`main.tf`

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.profile
}

module "staticsite" {
  source    = "git::https://github.com/kwo/terraform-modules.git//modules/staticsite?ref=v1.0.0"
  base_name = var.base_name
  logbucket = var.logbucket
  domain    = var.domain
  origins   = var.origins
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
```
