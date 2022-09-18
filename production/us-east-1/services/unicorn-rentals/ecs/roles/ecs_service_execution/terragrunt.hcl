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

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git@github.com:awazevr/terraform-aws-iam-module.git//iam?ref=v1.2.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  role_name               = "UnicornRentalsServiceExecutionRole"
  role_description        = "Service role for unicorn-rentals"
  assume_role_identifiers = ["ecs-tasks.amazonaws.com"]

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

  create_policy = true
  policy_json = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "kms:Decrypt",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
  policy_name        = "UnicornRentalsServiceExecutionPolicy"
  policy_description = "Service execution policy for unicorn-rentals"
  policy_tags        = {
    "Name" = "UnicornRentalsServiceExecutionPolicy"
  }

  role_tags = {
    Name        = "UnicornRentalsServiceExecutionRole"
  }
}