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
  source    = "git::https://github.com/kwo/terraform-modules.git//modules/staticsite?ref=v1.1.1"
  base_name = "my-project"
  logbucket = "the-site-logs"
  domain    = "example.com"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
```
