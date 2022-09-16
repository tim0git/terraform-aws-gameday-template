locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load application-level variables
  application_vars = yamldecode(file("application.yml"))

  # Extract the variables we need for easy access
  account_name               = local.account_vars.locals.account_name
  aws_region                 = local.region_vars.locals.aws_region
  name                       = local.application_vars.name
  cluster_settings           = local.application_vars.cluster_settings
  fargate_capacity_providers = local.application_vars.fargate_capacity_providers
}

terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//?version=4.1.1"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  cluster_name = local.name

  cluster_settings = local.cluster_settings

  fargate_capacity_providers = local.fargate_capacity_providers
}

