variable "github" {
  type = object({
    username = string
  })
  validation {
    condition     = length(var.github.username) > 0 && can(regex("^[a-zA-Z0-9-]+$", var.github.username))
    error_message = "Invalid GitHub username. Use only alphanumeric characters and hyphens."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d+$", var.region))
    error_message = "Invalid AWS region format."
  }
}

variable "project" {
  type = object({
    name  = string
    env   = string
    owner = string
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "lab"], var.project.env)
    error_message = "Allowed env values: dev, staging, prod, lab."
  }
}

variable "vpc" {
  type = object({
    cidr                            = string
    enable_nat_gateway              = bool
    single_nat_gateway              = bool
    create_database_subnet_group    = bool
    create_elasticache_subnet_group = bool
    create_egress_only_igw          = bool
    create_redshift_subnet_group    = bool
  })
  validation {
    condition     = can(cidrhost(var.vpc.cidr, 0))
    error_message = "Invalid IPv4 CIDR block."
  }
}

variable "eks" {
  type = object({
    kubernetes_version                       = string
    upgrade_policy                           = string
    instance_type                            = list(string)
    ami                                      = string
    endpoint_public_access                   = bool
    enable_cluster_creator_admin_permissions = bool
    domain                                   = list(string)
  })
  validation {
    condition     = can(regex("^1\\.[2-3][0-9]$", var.eks.kubernetes_version))
    error_message = "Invalid Kubernetes version format."
  }
  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.eks.upgrade_policy)
    error_message = "upgrade_policy must be STANDARD or EXTENDED."
  }
}

variable "db" {
  type = object({
    engine                              = string
    engine_version                      = string
    instance_class                      = string
    security_group_name                 = string
    allocated_storage                   = number
    manage_master_user_password         = bool
    iam_database_authentication_enabled = bool

    db_config = object({
      name     = string
      username = string
      port     = number
    })

    db_option_group = object({
      family               = string
      major_engine_version = string
    })
  })
  validation {
    condition     = var.db.engine == "postgres"
    error_message = "Engine must be 'postgres'."
  }
  validation {
    condition     = can(regex("^db\\.", var.db.instance_class))
    error_message = "Instance class must start with 'db.'."
  }
  validation {
    condition     = var.db.db_config.port > 1024 && var.db.db_config.port <= 65535 || var.db.db_config.port == 5432
    error_message = "Port must be 5432 or unprivileged TCP (>1024)."
  }
}

variable "domain" {
  type = object({
    name = string
  })
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.domain.name))
    error_message = "Invalid FQDN format."
  }
}

variable "ecr" {
  type = object({
    repository_image_tag_mutability = string
    repository_force_delete         = bool
    repository_image_scan_on_push   = bool
    create_lifecycle_policy         = bool
  })
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr.repository_image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}

variable "sns" {
  type = object({
    protocol = string
    endpoint = string
  })
  validation {
    condition     = contains(["email", "email-json", "https", "sqs", "lambda", "sms"], var.sns.protocol)
    error_message = "Unsupported SNS protocol."
  }
  validation {
    condition     = var.sns.protocol != "email" || can(regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", var.sns.endpoint))
    error_message = "Invalid email format for endpoint."
  }
}

variable "cognito" {
  type = object({
    user_pool_name   = string
    user_pool_domain = string
    user_pool_client = string
  })
}
