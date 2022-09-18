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

# Container talk to other services...
inputs = {
  role_name        = "UnicornRentalsTaskRole"
  role_description = "Task role for unicorn-rentals, allows the task to call AWS services"

  assume_role_identifiers = ["ecs-tasks.amazonaws.com"]

  create_policy = false
  policy_json = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
        ],
        "Effect" : "Allow",
        "Resource" : "*",
      }
    ]
  })
  policy_name        = "UnicornRentalsServiceTaskPolicy"
  policy_description = "Service task policy for unicorn-rentals"
  policy_tags        = {
    Name = "UnicornRentalsServiceTaskPolicy"
  }

  role_tags = {
    Name        = "UnicornRentalsTaskRole"
  }
}
