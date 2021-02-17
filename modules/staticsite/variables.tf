variable "base_name" {
  type        = string
  description = "base name of the project"
}

variable "domain" {
  type        = string
  description = "domain name to host for static site"
}

variable "domain_alias" {
  type        = string
  description = "subdomain to redirect to the main domain"
  default     = "www"
}

variable "logbucket" {
  type        = string
  description = "s3 bucket for storing cloudfront access logs"
}

variable "content_security_policy" {
  type    = string
  default = "default-src 'self'; base-uri 'self'; object-src 'none'"
}

variable "origins" {
  type = list(map(string))
}
