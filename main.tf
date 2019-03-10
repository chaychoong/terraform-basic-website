variable "region" {}
variable "aws_profile" {}
variable "dns_domain" {}
variable "email_verification_record" {}

variable "mx_records" {
  type = "list"
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile}"
  version = "~> 1.43.0"
}

module "domain" {
  source              = "tfmodules/domain"
  dns_domain          = "${var.dns_domain}"
  aws_profile         = "${var.aws_profile}"
  region              = "${var.region}"
  mx_records          = "${var.mx_records}"
  verification_record = "${var.email_verification_record}"
}

module "landing_page" {
  source              = "tfmodules/landing_page"
  function_name       = "landing_page"
  dns_domain          = "${var.dns_domain}"
  acm_certificate_arn = "${module.domain.acm_certificate_arn}"
  dns_zone_id         = "${module.domain.dns_zone_id}"
}
