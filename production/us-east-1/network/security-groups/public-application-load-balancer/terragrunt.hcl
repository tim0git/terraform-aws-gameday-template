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
  name        = "${local.account_name}-public-alb-sg"
  description = "Security Group for the Public ALB"
  vpc_id = dependency.vpc.outputs.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]

  egress_cidr_blocks = ["10.0.0.0/21"]
  egress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_with_cidr_blocks = [
    {
      from_port   = 8443
      to_port     = 8443
      protocol    = 6
      description = "ECS Service traffic to custom container port"
      cidr_blocks = "10.0.0.0/21"
    }
  ]
}