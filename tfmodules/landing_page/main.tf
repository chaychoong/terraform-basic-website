variable "function_name" {}
variable "dns_domain" {}
variable "dns_zone_id" {}
variable "acm_certificate_arn" {}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.dns_domain}-${var.function_name}-logs"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.dns_domain}-${var.function_name}"

  logging {
    target_bucket = "${aws_s3_bucket.logs.bucket}"
    target_prefix = "${var.dns_domain}/"
  }

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = "${aws_s3_bucket.site.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.site.arn}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.site.arn}"
    }
  ]
}
POLICY
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "cloudfront origin access identity"
}

resource "aws_cloudfront_distribution" "site_distribution" {
  enabled     = true
  aliases     = ["${var.dns_domain}"]
  price_class = "PriceClass_100"

  origin {
    domain_name = "${aws_s3_bucket.site.bucket_domain_name}"
    origin_id   = "${var.dns_domain}-origin"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 1000
    max_ttl                = 86400
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.dns_domain}-origin"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "site_record" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.dns_domain}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.site_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.site_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "www_site" {
  bucket = "www.${var.dns_domain}-${var.function_name}"

  website {
    redirect_all_requests_to = "https://${var.dns_domain}"
  }
}

resource "aws_s3_bucket_policy" "www_site_bucket_policy" {
  bucket = "${aws_s3_bucket.www_site.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.www_site.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_cloudfront_distribution" "www_site_distribution" {
  enabled     = true
  aliases     = ["www.${var.dns_domain}"]
  price_class = "PriceClass_100"

  origin {
    domain_name = "${aws_s3_bucket.www_site.website_endpoint}"
    origin_id   = "www.${var.dns_domain}-origin"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 1000
    max_ttl                = 86400
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "www.${var.dns_domain}-origin"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "www_site_record" {
  zone_id = "${var.dns_zone_id}"
  name    = "www.${var.dns_domain}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.www_site_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_site_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}
