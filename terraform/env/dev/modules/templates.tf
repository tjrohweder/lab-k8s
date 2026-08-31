resource "local_file" "aws_lbc_app" {
  content = templatefile("${path.module}/../../../../kubernetes/apps/aws-lb-controller-app.yaml.tpl", {
    github_user = var.github.username
  })

  filename = "${path.module}/../../../../kubernetes/apps/aws-lb-controller-app.yaml"
}

resource "local_file" "dagster_app" {
  content = templatefile("${path.module}/../../../../kubernetes/apps/dagster-app.yaml.tpl", {
    github_user = var.github.username
  })

  filename = "${path.module}/../../../../kubernetes/apps/dagster-app.yaml"
}

resource "local_file" "karpenter_app" {
  content = templatefile("${path.module}/../../../../kubernetes/apps/karpenter-app.yaml.tpl", {
    github_user = var.github.username
  })

  filename = "${path.module}/../../../../kubernetes/apps/karpenter-app.yaml"
}

resource "local_file" "aws_lb_controller_values" {
  content = templatefile("${path.module}/../../../../kubernetes/values/aws-lb-controller-values.yaml.tpl", {
    cluster_name = module.eks.cluster_name
    region       = var.region
    vpc_id       = module.vpc.vpc_id
    iam_role_arn = aws_iam_role.aws_lbc_role.arn
  })

  filename = "${path.module}/../../../../kubernetes/values/aws-lb-controller-values.yaml"
}

resource "local_file" "dagster_values" {
  content = templatefile("${path.module}/../../../../kubernetes/values/dagster-values.yaml.tpl", {
    dagster_iam_role_arn  = aws_iam_role.dagster_role.arn
    acm_certificate_arn   = module.acm.acm_certificate_arn
    cognito_user_pool_arn = aws_cognito_user_pool.dagster_auth.arn
    cognito_client_id     = aws_cognito_user_pool_client.dagster_client.id
    cognito_domain        = aws_cognito_user_pool_domain.dagster_domain.domain
    domain_name           = "dagster.${var.domain.name}"
    rds_endpoint          = module.db.db_instance_address
    s3_bucket_name        = module.dagster_s3_bucket.s3_bucket_id
    aws_region            = var.region
    ecr_repository_url    = module.ecr.repository_url
    sns_topic_arn         = aws_sns_topic.dagster_alerts.arn
  })

  filename = "${path.module}/../../../../kubernetes/values/dagster-values.yaml"
}

resource "local_file" "karpenter_values" {
  content = templatefile("${path.module}/../../../../kubernetes/values/karpenter-values.yaml.tpl", {
    cluster_name           = module.eks.cluster_name
    karpenter_iam_role_arn = aws_iam_role.karpenter_controller.arn
  })

  filename = "${path.module}/../../../../kubernetes/values/karpenter-values.yaml"
}

resource "local_file" "karpenter_nodepool" {
  content = templatefile("${path.module}/../../../../kubernetes/manifests/karpenter/karpenter-nodepool.yaml.tpl", {
    cluster_name             = module.eks.cluster_name
    karpenter_node_role_name = aws_iam_role.karpenter_node.name
  })

  filename = "${path.module}/../../../../kubernetes/manifests/karpenter/karpenter-nodepool.yaml"
}

resource "local_file" "dagster_secret" {
  content = templatefile("${path.module}/../../../../kubernetes/manifests/dagster/secret.yaml.tpl", {
    rds_secret_arn = module.db.db_instance_master_user_secret_arn
  })

  filename = "${path.module}/../../../../kubernetes/manifests/dagster/secret.yaml"
}

resource "local_file" "argocd_values" {
  content = templatefile("${path.module}/argocd/argocd-values.yaml.tpl", {
    acm_certificate_arn = module.acm.acm_certificate_arn
    domain_name = "argocd.${var.domain.name}"
  })

  filename = "${path.module}/argocd/argocd-values.yaml"
}

resource "local_file" "argocd_app_values" {
  content = templatefile("${path.module}/argocd/argocd-apps-values.yaml.tpl", {
    github_user = var.github.username
  })

  filename = "${path.module}/argocd/argocd-apps-values.yaml"
}
