locals {
  index_doc    = "index.html"
  index_src    = "<!DOCTYPE html><html><head><title>${var.domain}</title></head><body>${var.domain}</body></html>"
  error_doc    = "404.html"
  error_src    = "<!DOCTYPE html><html><head><title>${var.domain} - not found</title></head><body>not found</body></html>"
  robot_src    = "User-agent: *\nDisallow: /\n"
  s3_origin_id = "s3-${var.base_name}"
}

########## S3 bucket ##########

resource "aws_s3_bucket" "b" {
  bucket = var.domain
  acl    = "private"
  tags = {
    Name      = var.domain
    Project   = var.base_name
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket           = aws_s3_bucket.b.id
  key              = local.index_doc
  content          = local.index_src
  etag             = md5(local.index_src)
  cache_control    = "no-cache"
  content_type     = "text/html"
  content_encoding = "utf-8"
}

resource "aws_s3_bucket_object" "error" {
  bucket           = aws_s3_bucket.b.id
  key              = local.error_doc
  content          = local.error_src
  etag             = md5(local.error_src)
  cache_control    = "no-cache"
  content_type     = "text/html"
  content_encoding = "utf-8"
}

resource "aws_s3_bucket_object" "robots_txt" {
  bucket           = aws_s3_bucket.b.id
  key              = "robots.txt"
  content          = local.robot_src
  etag             = md5(local.robot_src)
  cache_control    = "public, max-age=86400"
  content_type     = "text/plain"
  content_encoding = "utf-8"
}

########## CloudFront Origin Permissions ##########

resource "aws_cloudfront_origin_access_identity" "oaid" {
  comment = "access-identity-${var.base_name}"
}

data "aws_iam_policy_document" "s3_b_policy_doc" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.b.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oaid.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_b_policy" {
  bucket = aws_s3_bucket.b.id
  policy = data.aws_iam_policy_document.s3_b_policy_doc.json
}

########## CloudFront Distribution ##########

resource "aws_cloudfront_distribution" "d" {
  enabled             = true
  http_version        = "http2"
  aliases             = [var.domain]
  comment             = var.base_name
  default_root_object = local.index_doc
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  logging_config {
    bucket          = data.aws_s3_bucket.logs.bucket_domain_name
    prefix          = "${var.domain}/"
    include_cookies = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oaid.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = aws_lambda_function.orsp.qualified_arn
    }
  }

  dynamic "origin" {
    for_each = var.origins
    content {
      origin_id   = origin.value.id
      origin_path = origin.value.path
      domain_name = origin.value.domain_name
      custom_origin_config {
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        https_port             = 443
        http_port              = 80
      }
      custom_header {
        name  = "x-host"
        value = var.domain
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.origins
    iterator = origin
    content {
      target_origin_id       = origin.value.id
      path_pattern           = origin.value.pattern
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = false
      forwarded_values {
        query_string = true
        headers      = ["Host", "Origin", "Referer"]
        cookies {
          forward = "all"
        }
      }
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/${local.error_doc}"
    error_caching_min_ttl = 20
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${local.error_doc}"
    error_caching_min_ttl = 20
  }

  tags = {
    Name      = var.domain
    Project   = var.base_name
    ManagedBy = "terraform"
  }

}
