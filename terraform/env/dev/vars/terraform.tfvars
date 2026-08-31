github = {
  username = "tjrohweder"
}

project = {
  name  = "lab"
  env   = "dev"
  owner = "Platform Engineering"
}

vpc = {
  cidr                            = "192.168.0.0/16"
  enable_nat_gateway              = true
  single_nat_gateway              = true
  create_database_subnet_group    = true
  create_elasticache_subnet_group = false
  create_egress_only_igw          = false
  create_redshift_subnet_group    = false
}

eks = {
  kubernetes_version                       = "1.36"
  upgrade_policy                           = "STANDARD"
  instance_type                            = ["t3a.medium"]
  ami                                      = "AL2023_x86_64_STANDARD"
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  domain                                   = ["tjrohweder.com"]
}

db = {
  engine                              = "postgres"
  engine_version                      = "18.6"
  instance_class                      = "db.t4g.micro"
  security_group_name                 = "postgres"
  allocated_storage                   = 15
  manage_master_user_password         = true
  iam_database_authentication_enabled = true

  db_config = {
    name     = "main"
    username = "db_admin"
    port     = 5432
  }

  db_option_group = {
    family               = "postgres18"
    major_engine_version = "18"
  }
}

domain = {
  name = "tjrohweder.com"
}

ecr = {
  repository_image_tag_mutability = "MUTABLE"
  repository_force_delete         = true
  repository_image_scan_on_push   = false
  create_lifecycle_policy         = false
}

sns = {
  protocol = "email"
  endpoint = "tjrohweder@gmail.com"
}

cognito = {
  user_pool_name   = "dagster-auth-pool"
  user_pool_domain = "dagster-test"
  user_pool_client = "dagster-alb-client"
}
