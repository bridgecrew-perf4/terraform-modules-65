locals {
  s3_redirect_origin_id = "s3-redirect-${var.base_name}"
}

########## S3 bucket ##########

resource "aws_s3_bucket" "redirect" {
  bucket        = "${var.domain}-redirect"
  acl           = "private"
  force_destroy = true

  website {
    redirect_all_requests_to = "https://${var.domain}"
  }

  tags = {
    Name      = "${var.domain_alias}.${var.domain}"
    Project   = var.base_name
    ManagedBy = "terraform"
  }
}

########## CloudFront Distribution ##########

resource "aws_cloudfront_distribution" "redirect" {
  enabled         = true
  http_version    = "http2"
  aliases         = ["${var.domain_alias}.${var.domain}"]
  comment         = "${var.base_name} redirect"
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  #default_root_object = local.index_doc # do not define a default root object or redirects to www.domain/ will be to domain/index.html

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  logging_config {
    bucket          = data.aws_s3_bucket.logs.bucket_domain_name
    prefix          = "${var.domain_alias}.${var.domain}/"
    include_cookies = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    origin_id   = local.s3_redirect_origin_id
    domain_name = aws_s3_bucket.redirect.website_endpoint
    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.s3_redirect_origin_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = false
    min_ttl                = "0"
    default_ttl            = "86400"
    max_ttl                = "2592000"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  tags = {
    Name      = var.domain
    Project   = var.base_name
    ManagedBy = "terraform"
  }

}
