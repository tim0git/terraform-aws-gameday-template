locals {

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_name               = local.account_vars.locals.account_name
  aws_account_id             = local.account_vars.locals.aws_account_id
  aws_region                 = local.region_vars.locals.aws_region

  min_size          = 3
  max_size          = 12
  desired_capacity  = 3
  image_id          = "ami-05fa00d4c63e32376" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type     = "t3.medium" # Bursting instance, so we don't pay for unused capacity use t3.2xlarge for production

  estimated_instance_warmup = 240 # 4 minutes
  target_tracking_value     = 100 # 100 requests per minute

  user_data = templatefile("./templates/user_data.tftpl", {})
}

terraform {
  source = "tfr:///terraform-aws-modules/autoscaling/aws//?version=6.5.2"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc_module" {
  config_path = "../../../network/vpc"
}

dependency "auto_scaling_group_security_group" {
  config_path = "../../../network/security-groups/autoscaling-group"
}

dependency "public_application_load_balancer" {
  config_path = "../../../network/load-balancers/public"
}

inputs = {
  name = "${local.account_name}-asg"

  # Auto scaling group
  asg_name                  = "${local.account_name}-auto-scaling-group"
  vpc_zone_identifier       = dependency.vpc_module.outputs.private_subnets
  security_groups           = [dependency.auto_scaling_group_security_group.outputs.security_group_id]
  target_group_arns         = dependency.public_application_load_balancer.outputs.target_group_arns
  health_check_type         = "EC2"
  min_size                  = local.min_size
  max_size                  = local.max_size
  desired_capacity          = local.desired_capacity
  wait_for_capacity_timeout = 0

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${local.account_name}-instance-profile"
  iam_role_path               = "/${local.account_name}/"
  iam_role_description        = "${local.account_name} EC2 IAM Instance Profile"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    AmazonS3ReadOnlyAccess       = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  # Launch template
  launch_template_name        = "${local.account_name}-launch-template"
  launch_template_description = "${local.account_name} Launch Template"
  update_default_version      = true

  image_id          = local.image_id
  instance_type     = local.instance_type
  ebs_optimized     = true
  user_data         = base64encode(local.user_data)

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 100
        volume_type           = "gp3" # General Purpose SSD (gp3) use io2 for intensive workloads
      }
    }
  ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 60
      checkpoint_percentages = [35, 70, 100] #Will wait for one minute at each checkpoint of the deployment to allow for checking deployment.
      instance_warmup        = local.estimated_instance_warmup
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  warm_pool = {
    pool_state                  = "Stopped" # "Stopped" instances will be kept in a pool and will be started when needed
    min_size                    = 1
    max_group_prepared_capacity = 2

    instance_reuse_policy = {
      reuse_on_scale_in = true
    }
  }

  # Target scaling policy schedule based on average CPU load
  scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = local.estimated_instance_warmup
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    },

#    predictive-scaling = {
#      policy_type = "PredictiveScaling"
#      predictive_scaling_configuration = {
#        mode                         = "ForecastAndScale"
#        scheduling_buffer_time       = 10
#        max_capacity_breach_behavior = "IncreaseMaxCapacity"
#        max_capacity_buffer          = 10
#        metric_specification = {
#          target_value = 32
#          predefined_scaling_metric_specification = {
#            predefined_metric_type = "ASGAverageCPUUtilization"
#            resource_label         = "testLabel"
#          }
#          predefined_load_metric_specification = {
#            predefined_metric_type = "ASGTotalCPUUtilization"
#            resource_label         = "testLabel"
#          }
#        }
#      }
#    },

#    request-count-per-target = {
#      policy_type               = "TargetTrackingScaling"
#      estimated_instance_warmup = local.estimated_instance_warmup
#      target_tracking_configuration = {
#        predefined_metric_specification = {
#          predefined_metric_type = "ALBRequestCountPerTarget"
#          resource_label         = "${dependency.public_application_load_balancer.outputs.lb_arn_suffix}/${dependency.public_application_load_balancer.outputs.target_group_arn_suffixes[0]}"
#        }
#        target_value = local.target_tracking_value
#      }
#    }
  }
}
