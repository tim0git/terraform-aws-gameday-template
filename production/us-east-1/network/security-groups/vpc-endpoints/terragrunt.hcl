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

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws//?version=4.10.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name        = "${local.account_name}-vpc-endpoints"
  description = "Security Group for the ${local.account_name} VPC endpoints ALLOW TLS inbound traffic"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
  ingress_rules       = ["https-443-tcp"]
}

