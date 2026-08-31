module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = var.project.name

  engine                      = var.db.engine
  engine_version              = var.db.engine_version
  instance_class              = var.db.instance_class
  allocated_storage           = var.db.allocated_storage
  manage_master_user_password = var.db.manage_master_user_password

  db_name  = var.db.db_config.name
  username = var.db.db_config.username
  port     = var.db.db_config.port

  iam_database_authentication_enabled = var.db.iam_database_authentication_enabled

  vpc_security_group_ids = [module.db_sg.security_group_id]

  # DB subnet group
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # DB parameter group
  family = var.db.db_option_group.family

  major_engine_version = var.db.db_option_group.major_engine_version
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name   = var.db.security_group_name
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.vpc.cidr
      description = "PostgreSQL network access"
  }, ]
}
