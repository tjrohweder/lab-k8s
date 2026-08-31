data "aws_route53_zone" "selected" {
  name = var.domain.name
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3"

  domain_name = var.domain.name
  zone_id     = data.aws_route53_zone.selected.zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain.name}",
    var.domain.name,
  ]

  wait_for_validation = true
}
