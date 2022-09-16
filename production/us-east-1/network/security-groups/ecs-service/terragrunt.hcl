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

dependency "public_application_load_balancer" {
  config_path = "../public-application-load-balancer"
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws//?version=4.10.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name        = "${local.account_name}-ecs-service"
  description = "Security Group for the ${local.account_name} ECS Service"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = dependency.public_application_load_balancer.outputs.security_group_id
    },
    {
      rule                     = "https-443-tcp"
      source_security_group_id = dependency.public_application_load_balancer.outputs.security_group_id
    },
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["http-80-tcp", "https-443-tcp","dns-udp", "dns-tcp", "postgresql-tcp", "mysql-tcp"]
}

