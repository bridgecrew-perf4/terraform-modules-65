########## Route53 ##########

resource "aws_route53_record" "apex_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.d.domain_name
    zone_id                = aws_cloudfront_distribution.d.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.d.domain_name
    zone_id                = aws_cloudfront_distribution.d.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "redirect_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.domain_alias}.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "redirect_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.domain_alias}.${var.domain}"
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}
