module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = var.project.name
  cidr = var.vpc.cidr
  azs  = data.aws_availability_zones.available.names

  private_subnets = [
    cidrsubnet(var.vpc.cidr, 4, 0),
    cidrsubnet(var.vpc.cidr, 4, 1),
    cidrsubnet(var.vpc.cidr, 4, 2),
  ]

  public_subnets = [
    cidrsubnet(var.vpc.cidr, 8, 50),
    cidrsubnet(var.vpc.cidr, 8, 51),
    cidrsubnet(var.vpc.cidr, 8, 52),
  ]

  database_subnets = [
    cidrsubnet(var.vpc.cidr, 8, 80),
    cidrsubnet(var.vpc.cidr, 8, 81),
    cidrsubnet(var.vpc.cidr, 8, 82),
  ]

  enable_nat_gateway              = var.vpc.enable_nat_gateway
  single_nat_gateway              = var.vpc.single_nat_gateway
  create_database_subnet_group    = var.vpc.create_database_subnet_group
  create_elasticache_subnet_group = var.vpc.create_elasticache_subnet_group
  create_egress_only_igw          = var.vpc.create_egress_only_igw
  create_redshift_subnet_group    = var.vpc.create_redshift_subnet_group
}
