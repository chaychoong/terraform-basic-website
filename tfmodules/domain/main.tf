variable "dns_domain" {}
variable "aws_profile" {}
variable "region" {}
variable "mx_records" {
  type = "list"
}

variable "verification_record" {}

resource "aws_route53_zone" "site_zone" {
  name = "${var.dns_domain}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "ns" {
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "${var.dns_domain}"
  type    = "NS"
  ttl     = "300"

  records = [
    "${aws_route53_zone.site_zone.name_servers.0}",
    "${aws_route53_zone.site_zone.name_servers.1}",
    "${aws_route53_zone.site_zone.name_servers.2}",
    "${aws_route53_zone.site_zone.name_servers.3}",
  ]
}

resource "aws_route53_record" "ses_amazonses_verification_record" {
  count   = "${var.verification_record == "" ? 0 : 1}"
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "${var.dns_domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["${var.verification_record}"]
}

resource "aws_route53_record" "email" {
  zone_id = "${aws_route53_zone.site_zone.zone_id}"
  name    = "${var.dns_domain}"
  type    = "MX"
  ttl     = "300"

  records = "${var.mx_records}"
}

module "us_east_cert" {
  source      = "us_east_cert"
  dns_domain  = "${var.dns_domain}"
  aws_profile = "${var.aws_profile}"
  dns_zone_id = "${aws_route53_zone.site_zone.id}"
}

output "acm_certificate_arn" {
  value = "${module.us_east_cert.acm_certificate_arn}"
}

output "dns_zone_id" {
  value = "${aws_route53_zone.site_zone.zone_id}"
}
