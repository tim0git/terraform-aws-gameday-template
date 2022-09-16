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
  source = "tfr:///terraform-aws-modules/alb/aws//?version=7.0.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc_module" {
  config_path = "../../vpc"
}

dependency "public_application_load_balancer" {
  config_path = "../../security-groups/public-application-load-balancer"
}

inputs = {
  name               = "${local.account_name}-public-alb"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = dependency.vpc_module.outputs.vpc_id
  subnets            = dependency.vpc_module.outputs.public_subnets
  security_groups    = [dependency.public_application_load_balancer.outputs.security_group_id]

  access_logs = {
    bucket = "${local.aws_account_id}-alb-logs"
    prefix = "${local.account_name}-public-alb"
  }

  target_groups = [
    {
      name_prefix      = "asg"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        protocol            = "HTTP"
        port                = 80
        path                = "/"
        timeout             = "10"
        interval            = "20"
        healthy_threshold   = "3"
        unhealthy_threshold = "2"
      }
    }
  ]

  http_tcp_listener_rules = [
    {
      https_listener_index = 0

      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]

      conditions = [{
        path_patterns = ["/*"]
      }]
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type        = "fixed-response"
        fixed_response = {
            content_type = "text/plain"
            message_body = "Forbidden 403"
            status_code  = "403"
        }
    }
  ]
}
