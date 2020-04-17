data "aws_route53_zone" "domain_record" {
  name = "${var.domain}."
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dns_validation" {
  name = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  zone_id = data.aws_route53_zone.domain_record.zone_id
  ttl = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.dns_validation.fqdn]
}

resource "aws_route53_record" "example" {
  name    = aws_api_gateway_domain_name.dns.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.domain_record.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.dns.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.dns.regional_zone_id
  }
}