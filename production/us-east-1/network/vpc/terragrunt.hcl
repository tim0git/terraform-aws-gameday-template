locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_name = local.account_vars.locals.account_name
  aws_region   = local.region_vars.locals.aws_region
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws//?version=3.14.2"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name = local.account_name
  cidr = "10.0.0.0/21" #2048 IP available

  azs              = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets  = ["10.0.0.0/25", "10.0.0.128/25", "10.0.1.0/25"]   #128 IP addresses available per subnet
  public_subnets   = ["10.0.1.128/25", "10.0.2.0/25", "10.0.2.128/25"] #128 IP addresses available per subnet
  database_subnets = ["10.0.3.0/25", "10.0.3.128/25", "10.0.4.0/25"]   #128 IP addresses available per subnet

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  #896 IP addresses available for additional subnets

  enable_ipv6 = true

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 30
}
