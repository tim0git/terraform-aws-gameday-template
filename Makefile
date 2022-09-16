preflight check:
	terragrunt -v
	terraform -v
	aws --version

configure aws profile:
	aws configure --profile UnicornRentalsProduction

set aws cli default profile:
	export AWS_DEFAULT_PROFILE=UnicornRentalsProduction

vpc:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/vpc

log buckets:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/logs/s3-access
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/logs/public-alb-access

cluster:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/clusters/ecs/common

security groups:
	terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups

vpc endpoints:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/vpc-endpoints

public load balancer:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/load-balancers/public

autoscaling group:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/services/unicorn-rentals/autoscaling-group-ec2

aurora serverless:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora

dynamodb:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/dynamodb

rds:
	terragrunt apply --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/rds

get aurora database credentials:
	terragrunt output cluster_master_username --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora
	terragrunt output cluster_master_password --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/database/aurora

detect changes to security groups:
	terragrunt plan --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/security-groups

detect changes to vpc:
	terragrunt plan --terragrunt-non-interactive --terragrunt-working-dir ./production/us-east-1/network/vpc
