preflight_check:
	terragrunt -v
	terraform -v
	aws --version

configure_aws_profile:
	aws configure --profile UnicornRentalsProduction

set_aws_cli_default_profile:
	export AWS_DEFAULT_PROFILE=UnicornRentalsProduction

vpc:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/vpc

log_buckets:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/logs/s3-access
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/logs/public-alb-access

cluster:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/clusters/ecs/common

security_groups_alb_endpoints:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups/public-application-load-balancer
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups/vpc-endpoints

security_groups_ecs_autoscaling_group:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups/autoscaling-group
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups/ecs-service

security_groups_rds:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups/rds

vpc_endpoints:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/vpc-endpoints

public_load_balancer:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/load-balancers/public

autoscaling_group:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/services/unicorn-rentals/autoscaling-group-ec2

ecs_service:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/services/unicorn-rentals/ecs/roles
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/services/unicorn-rentals/ecs/ecr
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/services/unicorn-rentals/ecs/service

aurora_serverless:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora

dynamodb:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/dynamo

rds:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds

get_aurora_database_credentials:
	terragrunt output cluster_master_username --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora
	terragrunt output cluster_master_password --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora
	terragrunt output cluster_port --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora
	terragrunt output cluster_database_name --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora
	terragrunt output cluster_endpoint --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora
	terragrunt output cluster_reader_endpoint --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora

get_rds_database_credentials:
	terragrunt output db_instance_username --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds
	terragrunt output db_instance_password --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds
	terragrunt output db_instance_port --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds
	terragrunt output db_instance_name --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds
	terragrunt output db_instance_endpoint --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds

detect_changes_to_security_groups:
	terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups

detect_changes_to_vpc:
	terragrunt plan --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/vpc

remove_terragrunt_cache_and_lock:
	find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;
	find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
