variable "aws_profile" {}
variable "dns_domain" {}
variable "dns_zone_id" {}

provider "aws" {
  region  = "us-east-1"
  profile = "${var.aws_profile}"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.dns_domain}"
  validation_method = "DNS"

  tags {
    Name = "us-east-1-cert"
  }

  subject_alternative_names = ["${var.dns_domain}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.dns_zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = "${aws_acm_certificate.cert.arn}"

  depends_on = ["aws_route53_record.validation"]
}

output "acm_certificate_arn" {
  value = "${aws_acm_certificate_validation.cert_validation.certificate_arn}"
}
