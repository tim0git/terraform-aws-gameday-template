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
  source = "tfr:///terraform-aws-modules/vpc/aws//modules/vpc-endpoints/?version=3.14.4"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "vpc_endpoints_sg" {
  config_path = "../security-groups/vpc-endpoints"
}

inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  security_group_ids = [dependency.vpc.outputs.default_security_group_id]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([dependency.vpc.outputs.intra_route_table_ids, dependency.vpc.outputs.private_route_table_ids, dependency.vpc.outputs.public_route_table_ids])
      policy          = templatefile("./templates/endpoint_policy.tftpl", { vpc_id = dependency.vpc.outputs.vpc_id, action = "dynamodb:*" })
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      security_group_ids  = [dependency.vpc_endpoints_sg.outputs.security_group_id]
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
    lambda = {
      service             = "lambda"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
    ecs = {
      service             = "ecs"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
    ecs_telemetry = {
      create              = false
      service             = "ecs-telemetry"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      security_group_ids  = [dependency.vpc_endpoints_sg.outputs.security_group_id]
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      policy              = templatefile("./templates/endpoint_policy.tftpl", { vpc_id = dependency.vpc.outputs.vpc_id, action = "*" })
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      policy              = templatefile("./templates/endpoint_policy.tftpl", { vpc_id = dependency.vpc.outputs.vpc_id, action = "*" })
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      security_group_ids  = [dependency.vpc_endpoints_sg.outputs.security_group_id]
    },
    codedeploy = {
      service             = "codedeploy"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
    codedeploy_commands_secure = {
      service             = "codedeploy-commands-secure"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    }
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      policy              = templatefile("./templates/endpoint_policy.tftpl", { vpc_id = dependency.vpc.outputs.vpc_id, action = "*" })
    },
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
    },
  }
}
