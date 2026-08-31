module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.25"

  name                                     = "${var.project.name}-cluster"
  kubernetes_version                       = var.eks.kubernetes_version
  endpoint_public_access                   = var.eks.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.eks.enable_cluster_creator_admin_permissions

  upgrade_policy = {
    support_type = var.eks.upgrade_policy
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
      before_compute    = true
    }

    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
      before_compute    = true
    }

    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
      before_compute    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    metrics-server = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }

    kube-state-metrics = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }

    external-dns = {
      resolve_conflicts        = "OVERWRITE"
      most_recent              = true
      service_account_role_arn = aws_iam_role.external_dns.arn
      configuration_values = jsonencode({
        sources       = ["ingress"]
        domainFilters = ["tjrohweder.com"]
        env = [
          {
            name  = "AWS_REGION"
            value = "${var.region}"
          }
        ]
      })
    }

    aws-secrets-store-csi-driver-provider = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project.name}-cluster"
  }

  eks_managed_node_groups = {
    "${var.project.name}-node-pool" = {
      ami_type       = var.eks.ami
      instance_types = var.eks.instance_type

      min_size     = 1
      max_size     = 10
      desired_size = 2
    }
  }
}
