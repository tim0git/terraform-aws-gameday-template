locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_name               = local.account_vars.locals.account_name
  aws_account_id             = local.account_vars.locals.aws_account_id
  aws_region                 = local.region_vars.locals.aws_region
  environment                = local.account_vars.locals.environment

  service_name   = "${local.account_name}"
  container_port = 8443
  listener_port    = 80
  desired_count  = 3

  target_tracking_scaling_value = 300
  min_capacity = 3
  max_capacity = 24
}

dependency "vpc_module" {
  config_path = "../../../../network/vpc"
}

dependency "cluster" {
  config_path = "../../../../network/clusters/ecs/common"
}

dependency "public_application_load_balancer" {
  config_path = "../../../../network/load-balancers/public"
}

dependency "ecs_service_security_group" {
  config_path = "../../../../network/security-groups/ecs-service"
}

terraform {
  source = "git@github.com:awazevr/terraform-aws-ecs-module.git//ecs/service-v2?ref=v4.2.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  environment    = local.environment
  region         = local.aws_region
  service_name   = local.service_name

  launch_type                          = "FARGATE"
  deployment_type                      = "ECS"
  enable_autoscaling                   = false
  network_mode                         = "awsvpc"
  desired_count                        = local.desired_count

  enable_autoscaling = true
  autoscaling_policy_type = "TargetTrackingScaling"
  target_tracking_scaling_type = "ALBRequestCountPerTarget"
  target_tracking_scaling_value = local.target_tracking_scaling_value
  min_capacity = local.min_capacity
  max_capacity = local.max_capacity

  ignore_container_definitions_changes = false
  task_definition_settings = {
    name                 = lower(local.service_name)
    image                = lower("${local.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${local.account_name}:latest")
    healthcheck_endpoint = ""
    launch_type          = "FARGATE"
    cpu                  = 256
    memory               = 512
    container_name       = lower("${local.service_name}-container")
    container_port       = local.container_port
  }

  env_vars = [
    {
      name = "PORT"
      value = tostring(local.container_port)
    }
  ]

#  secrets = [
#    {
#      name : "PASSWORD",
#      valueFrom : "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/password"
#    }
#  ]

  ecs_cluster_id = dependency.cluster.outputs.cluster_id
  ecs_cluster_name = "common-cluster-v1"

  lookup_vpc = true
  vpc_lookup_tag = {
    Name = "${local.account_name}"
  }

  task_role_arn      = "arn:aws:iam::${local.aws_account_id}:role/UnicornRentalsTaskRole"
  execution_role_arn = "arn:aws:iam::${local.aws_account_id}:role/UnicornRentalsServiceExecutionRole"

  security_group_ids = [
    dependency.ecs_service_security_group.outputs.security_group_id
  ]

  port_mapping = [
    {
      containerPort = local.container_port
    }
  ]

  network_configuration = [
    {
      subnets          = dependency.vpc_module.outputs.private_subnets
      assign_public_ip = false
    }
  ]

  create_target_group   = true
  target_type           = "ip"
  target_group_protocol = "HTTP"
  target_group_health_check = [
    {
      port                = local.container_port
      interval            = "20"
      path                = "/api/health"
      protocol            = "HTTP"
      timeout             = "15"
      healthy_threshold   = "2"
      unhealthy_threshold = "3"
      matcher             = "200,302"
    }
  ]
  create_lb_listener_rule = true
  lb_listener_rules = {
    path-pattern = "/*"
  }

  lookup_alb           = true
  lookup_alb_name      = "${local.account_name}-public-alb"
  lookup_listener_port = local.listener_port

  create_log_group = true
  log_group_name   = lower(local.service_name)
  log_driver       = "awslogs"
  log_driver_options = {
    awslogs-region        = local.aws_region
    awslogs-group         = lower(local.service_name)
    awslogs-stream-prefix = "ecs"
  }

  tags = {
    Name = lower(local.service_name)
  }
}
