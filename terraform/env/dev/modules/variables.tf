variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type = object({
    name  = string
    env   = string
    owner = string
  })
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
    error_message = "The VPC CIDR must be a valid IPv4 CIDR block"
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
  })
}

variable "db" {
  type = object({
    identifier                          = string
    engine                              = string
    engine_version                      = string
    instance_class                      = string
    security_group_name                 = string
    allocated_storage                   = number
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
}
