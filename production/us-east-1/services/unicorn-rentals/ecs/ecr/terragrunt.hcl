locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  ecr_lifecycle_policies = yamldecode(file(find_in_parent_folders("ecr_lifecycle_templates.yml")))

  # Extract the variables we need for easy access
  account_name               = local.account_vars.locals.account_name
  aws_account_id             = local.account_vars.locals.aws_account_id
  aws_region                 = local.region_vars.locals.aws_region
  environment                = local.account_vars.locals.environment
  ecr_lifecycle_policy       = local.ecr_lifecycle_policies.keep_last_10
}

terraform {
  source = "tfr:///terraform-aws-modules/ecr/aws//?version=1.4.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  repository_name = local.account_name

  repository_read_write_access_arns = [
    "arn:aws:iam::${local.aws_account_id}:root",
    "arn:aws:iam::063778477900:role/UnicornRentalsServiceExecutionRole"
  ]

  create_lifecycle_policy           = true
  repository_lifecycle_policy = local.ecr_lifecycle_policy

  repository_image_scan_on_push = true
  repository_image_tag_mutability = "MUTABLE"

  repository_force_delete = true

  tags = {
    Environment = local.environment
    Name        = "${local.account_name}"
  }
}
