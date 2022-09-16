# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name   = "unicorn-rentals"
  aws_account_id = "063778477900"
  aws_profile    = "UnicornRentalsProduction"
  environment    = "Production"
}