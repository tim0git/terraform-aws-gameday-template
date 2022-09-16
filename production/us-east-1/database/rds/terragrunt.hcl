locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_name               = local.account_vars.locals.account_name
  aws_account_id             = local.account_vars.locals.aws_account_id
  aws_region                 = local.region_vars.locals.aws_region
}

terraform {
  source = "tfr:///terraform-aws-modules/rds/aws//?version=5.1.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc_module" {
  config_path = "../../network/vpc"
}

dependency "rds_sg" {
  config_path = "../../network/security-groups/rds"
}

inputs = {
  identifier = "${local.account_name}"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres" #"mysql"
  engine_version       = "14.1" #"8.0.27"
  family               = "postgres14" # "mysql8.0"
  major_engine_version = "14"         # "8.0"
  instance_class       = "db.t4g.large"


  allocated_storage     = 40
  max_allocated_storage = 100

  db_name  = "unicornrentals"
  username = "unicorn_rentals"
  port     = 5432 #3306

  multi_az               = true
  db_subnet_group_name   = dependency.vpc_module.outputs.database_subnet_group
  vpc_security_group_ids = [dependency.rds_sg.outputs.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"] #"general"
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${local.account_name}-rds-monitoring-role-name"
  monitoring_role_use_name_prefix       = false
  monitoring_role_description           = "${local.account_name} RDS monitoring role"

  parameters = [
    {
      name  = "autovacuum" # "character_set_client"
      value = 1 # "utf8mb4"
    },
    {
      name  = "client_encoding" # "character_set_server"
      value = "utf8" # "utf8mb4"
    }
  ]

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}
