module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.20"

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
    }
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

module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name             = "karpenter-controller-${module.eks.cluster_name}"

  karpenter_controller_cluster_name       = module.eks.cluster_name
  karpenter_controller_node_iam_role_arns = [aws_iam_role.karpenter_node.arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}
