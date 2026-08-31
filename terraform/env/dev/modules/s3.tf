data "aws_caller_identity" "current" {}

module "dagster_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5"

  bucket = "lab-dagster-storage-${data.aws_caller_identity.current.account_id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  force_destroy = true
}
