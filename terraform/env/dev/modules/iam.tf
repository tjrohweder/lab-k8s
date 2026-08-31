resource "aws_iam_role" "karpenter_node" {
  name = "KarpenterNodeRole-${module.eks.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "KarpenterNodeProfile-${module.eks.cluster_name}"
  role = aws_iam_role.karpenter_node.name
}

data "aws_iam_policy_document" "karpenter_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name               = "karpenter-controller-${module.eks.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_trust_policy.json
}

data "aws_iam_policy_document" "karpenter_controller_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "pricing:GetProducts",
      "ssm:GetParameter",
      "iam:CreateInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfiles",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:TagInstanceProfile"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.karpenter_node.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name   = "karpenter-controller-policy-${module.eks.cluster_name}"
  policy = data.aws_iam_policy_document.karpenter_controller_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

data "aws_iam_policy_document" "dagster_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:dagster:dagster"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dagster_role" {
  name               = "dagster-role-${var.project.name}"
  assume_role_policy = data.aws_iam_policy_document.dagster_trust_policy.json
}

data "aws_iam_policy_document" "dagster_s3_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      module.dagster_s3_bucket.s3_bucket_arn,
      "${module.dagster_s3_bucket.s3_bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.dagster_alerts.arn]
  }
}

resource "aws_iam_policy" "dagster_s3_policy" {
  name   = "dagster-s3-access-policy-${var.project.name}"
  policy = data.aws_iam_policy_document.dagster_s3_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "dagster_s3_attach" {
  role       = aws_iam_role.dagster_role.name
  policy_arn = aws_iam_policy.dagster_s3_policy.arn
}

data "aws_iam_policy_document" "dagster_secrets_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [module.db.db_instance_master_user_secret_arn]
  }
}

resource "aws_iam_policy" "dagster_secrets" {
  name   = "dagster-secrets-policy-${var.project.name}"
  policy = data.aws_iam_policy_document.dagster_secrets_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "dagster_secrets_attach" {
  role       = aws_iam_role.dagster_role.name
  policy_arn = aws_iam_policy.dagster_secrets.arn
}

data "aws_iam_policy_document" "aws_lbc_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_lbc_role" {
  name               = "aws-load-balancer-controller-${var.project.name}"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_trust_policy.json
}

data "http" "aws_lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "aws_lbc_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${var.project.name}"
  policy = data.http.aws_lbc_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "aws_lbc_attach" {
  role       = aws_iam_role.aws_lbc_role.name
  policy_arn = aws_iam_policy.aws_lbc_policy.arn
}

resource "aws_eks_access_entry" "karpenter_node_access" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"
}

data "aws_iam_policy_document" "external_dns_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "external-dns-${var.project.name}"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json
}

data "aws_iam_policy_document" "external_dns_policy" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name   = "external-dns-${var.project.name}"
  policy = data.aws_iam_policy_document.external_dns_policy.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "kubernetes_cluster_role_v1" "secrets_store_sync" {
  metadata {
    name = "secrets-store-csi-driver-secret-sync"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "secrets_store_sync" {
  metadata {
    name = "secrets-store-csi-driver-secret-sync"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.secrets_store_sync.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "secrets-store-csi-driver"
    namespace = "aws-secrets-manager"
  }
}
