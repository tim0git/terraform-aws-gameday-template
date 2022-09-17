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
  source = ".//module"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc_module" {
  config_path = "../../network/vpc"
}

inputs = {

  name = "${local.account_name}"

  database_engine_configuration = {
    engine  = "aurora-postgresql" # "aurora-mysql"
    version = "13.6" # "8.0.mysql_aurora.3.02.0"
    family = "aurora-postgresql13" # "aurora-mysql8.0
  }

  vpc_id = dependency.vpc_module.outputs.vpc_id

  database_subnets = dependency.vpc_module.outputs.database_subnets

  private_subnets_cidr_blocks = dependency.vpc_module.outputs.private_subnets_cidr_blocks

  scaling_configuration = {
    min_capacity = 2
    max_capacity = 10
  }
}