########## Certificate ##########

resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = var.domain
  subject_alternative_names = var.domain_alias == "" ? [] : ["${var.domain_alias}.${var.domain}"]
  validation_method         = "DNS"
  tags = {
    Name      = var.domain
    Project   = var.base_name
    ManagedBy = "terraform"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  zone_id         = data.aws_route53_zone.main.zone_id
  ttl             = 60
  allow_overwrite = true
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
}

# Triggers the ACM wildcard certificate validation event
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
