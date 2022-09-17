data "aws_rds_engine_version" "aurora" {
  engine  = var.database_engine_configuration.engine
  version = var.database_engine_configuration.version
}

module "aurora_serverless_v2" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.5.1"

  name              = var.name
  engine            = data.aws_rds_engine_version.aurora.engine
  engine_mode       = "provisioned"
  engine_version    = data.aws_rds_engine_version.aurora.version
  storage_encrypted = true

  database_name     = var.database_name

  create_db_subnet_group = false
  db_subnet_group_name   = var.name

  vpc_id                = var.vpc_id
  subnets               = var.database_subnets
  create_security_group = true
  allowed_cidr_blocks   = var.private_subnets_cidr_blocks

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  copy_tags_to_snapshot = true
  deletion_protection   = true

  db_parameter_group_name         = aws_db_parameter_group.aurora_serverless.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_serverless.id

  serverlessv2_scaling_configuration = {
    min_capacity = var.scaling_configuration.min_capacity
    max_capacity = var.scaling_configuration.max_capacity
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
    two = {}
  }
}

resource "aws_db_parameter_group" "aurora_serverless" {
  name        = "${var.name}-aurora-db-serverless-parameter-group"
  family      = var.database_engine_configuration.family
  description = "${var.name}-aurora-db-serverless-parameter-group"
  tags        = var.tags
}

resource "aws_rds_cluster_parameter_group" "aurora_serverless" {
  name        = "${var.name}-aurora-serverless-cluster-parameter-group"
  family      = var.database_engine_configuration.family
  description = "${var.name}-aurora-serverless-cluster-parameter-group"
  tags        = var.tags
}