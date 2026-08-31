module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.2"

  repository_name                 = "dagster-dummy-pipeline-${var.project.name}"
  repository_image_tag_mutability = var.ecr.repository_image_tag_mutability
  repository_force_delete         = var.ecr.repository_force_delete
  repository_image_scan_on_push   = var.ecr.repository_image_scan_on_push
  create_lifecycle_policy         = var.ecr.create_lifecycle_policy
}
