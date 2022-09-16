locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the variables we need for easy access
  aws_account_id = local.account_vars.locals.aws_account_id
  account_name   = local.account_vars.locals.account_name
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "ecs_service_sg" {
  config_path = "../ecs-service"
}

dependency "autoscaling_group_sg" {
  config_path = "../autoscaling-group"
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws//?version=4.10.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name        = "${local.account_name}-rds"
  description = "Security Group for the ${local.account_name} rds"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from ECS Service"
      source_security_group_id = dependency.ecs_service_sg.outputs.security_group_id
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from EC2 Autoscaling Group"
      source_security_group_id = dependency.autoscaling_group_sg.outputs.security_group_id
    }
  ]
}

