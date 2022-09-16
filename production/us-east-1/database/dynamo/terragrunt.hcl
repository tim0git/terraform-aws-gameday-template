locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_name               = local.account_vars.locals.account_name
  aws_account_id             = local.account_vars.locals.aws_account_id
  aws_region                 = local.region_vars.locals.aws_region

  hash_key = "id"
  range_key = "title"
  gsi_range_key = "age"
}

terraform {
  source = "tfr:///terraform-aws-modules/dynamodb-table/aws//?version=3.1.1"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name                = "${local.account_name}"
  hash_key            = local.hash_key
  range_key           = local.range_key
  billing_mode        = "PROVISIONED"
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = true
  read_capacity       = 5
  write_capacity      = 5
  autoscaling_enabled = true

  autoscaling_read = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 45
    max_capacity       = 10
  }

  autoscaling_write = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 45
    max_capacity       = 10
  }

  autoscaling_indexes = {
    TitleIndex = {
      read_max_capacity  = 30
      read_min_capacity  = 10
      write_max_capacity = 30
      write_min_capacity = 10
    }
  }

  attributes = [
    {
      name = local.hash_key
      type = "N"
    },
    {
      name = local.range_key
      type = "S"
    },
    {
      name = local.gsi_range_key
      type = "N"
    }
  ]

  global_secondary_indexes = [
    {
      name               = "TitleIndex"
      hash_key           = local.range_key
      range_key          = local.gsi_range_key
      projection_type    = "INCLUDE"
      non_key_attributes = [local.hash_key]
      write_capacity     = 10
      read_capacity      = 10
    }
  ]

  ttl_attribute_name = "ttl"
  ttl_enabled        = true
}
