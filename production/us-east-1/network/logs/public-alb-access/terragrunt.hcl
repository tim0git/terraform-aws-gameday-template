locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  s3_lifecycle_templates = yamldecode(file(find_in_parent_folders("s3_lifecycle_templates.yml")))

  # Extract the variables we need for easy access
  aws_account_id = local.account_vars.locals.aws_account_id
  account_name   = local.account_vars.locals.account_name
}

terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//?version=3.3.0"
}

include {
  path = find_in_parent_folders()
}

dependency "s3_access_logs" {
  config_path = "../s3-access"
}

inputs = {
  bucket = "${local.aws_account_id}-alb-logs",
  acl    = "log-delivery-write"

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Bucket policies
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_elb_log_delivery_policy        = true

  versioning = {
    status     = true
    mfa_delete = false
  }

  logging = {
    target_bucket = dependency.s3_access_logs.outputs.s3_bucket_id
    target_prefix = "${local.aws_account_id}-alb-logs/"
  }

  lifecycle_rule = local.s3_lifecycle_templates.standard_30_glacier_60_delete_365
}
