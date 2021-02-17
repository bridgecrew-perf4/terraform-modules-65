output "bucket" {
  value = aws_s3_bucket.b.bucket
}

output "cert_arn" {
  value = aws_acm_certificate.cert.arn
}

output "distro" {
  value = aws_cloudfront_distribution.d.arn
}

output "url" {
  value = "https://${aws_route53_record.apex_a.fqdn}/"
}
