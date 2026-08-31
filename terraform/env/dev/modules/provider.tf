terraform {
  required_version = ">=1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3"
    }
  }

  backend "s3" {}
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project.name
      Owner   = var.project.owner
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
