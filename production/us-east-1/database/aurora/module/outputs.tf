################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = try(module.aurora_serverless_v2.cluster_arn, "")
}

output "cluster_id" {
  description = "The RDS Cluster Identifier"
  value       = try(module.aurora_serverless_v2.cluster_id, "")
}

output "cluster_resource_id" {
  description = "The RDS Cluster Resource ID"
  value       = try(module.aurora_serverless_v2.cluster_resource_id, "")
}

output "cluster_members" {
  description = "List of RDS Instances that are a part of this cluster"
  value       = try(module.aurora_serverless_v2.cluster_members, "")
}

output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = try(module.aurora_serverless_v2.cluster_endpoint, "")
}

output "cluster_reader_endpoint" {
  description = "A read-only endpoint for the cluster, automatically load-balanced across replicas"
  value       = try(module.aurora_serverless_v2.cluster_reader_endpoint, "")
}

output "cluster_engine_version_actual" {
  description = "The running version of the cluster database"
  value       = try(module.aurora_serverless_v2.cluster_engine_version_actual, "")
}

# database_name is not set on `aws_rds_cluster` resource if it was not specified, so can't be used in output
output "cluster_database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = var.name
}

output "cluster_port" {
  description = "The database port"
  value       = try(module.aurora_serverless_v2.cluster_port, "")
}

output "cluster_master_password" {
  description = "The database master password"
  value       = try(module.aurora_serverless_v2.cluster_master_password, "")
  sensitive   = true
}

output "cluster_master_username" {
  description = "The database master username"
  value       = try(module.aurora_serverless_v2.cluster_master_username, "")
  sensitive   = true
}

output "cluster_hosted_zone_id" {
  description = "The Route53 Hosted Zone ID of the endpoint"
  value       = try(module.aurora_serverless_v2.cluster_hosted_zone_id, "")
}

################################################################################
# Cluster Instance(s)
################################################################################

output "cluster_instances" {
  description = "A map of cluster instances and their attributes"
  value       = module.aurora_serverless_v2.cluster_instances
}

################################################################################
# Cluster Endpoint(s)
################################################################################

output "additional_cluster_endpoints" {
  description = "A map of additional cluster endpoints and their attributes"
  value       = module.aurora_serverless_v2.additional_cluster_endpoints
}

################################################################################
# Cluster IAM Roles
################################################################################

output "cluster_role_associations" {
  description = "A map of IAM roles associated with the cluster and their attributes"
  value       = module.aurora_serverless_v2.cluster_role_associations
}

################################################################################
# Enhanced Monitoring
################################################################################

output "enhanced_monitoring_iam_role_name" {
  description = "The name of the enhanced monitoring role"
  value       = try(module.aurora_serverless_v2.enhanced_monitoring_iam_role_name, "")
}

output "enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the enhanced monitoring role"
  value       = try(module.aurora_serverless_v2.enhanced_monitoring_iam_role_arn, "")
}

output "enhanced_monitoring_iam_role_unique_id" {
  description = "Stable and unique string identifying the enhanced monitoring role"
  value       = try(module.aurora_serverless_v2.enhanced_monitoring_iam_role_unique_id, "")
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The security group ID of the cluster"
  value       = try(module.aurora_serverless_v2.security_group_id, "")
}

################################################################################
# Cluster Parameter Group
################################################################################

output "db_cluster_parameter_group_arn" {
  description = "The ARN of the DB cluster parameter group created"
  value       = try(module.aurora_serverless_v2.db_cluster_parameter_group_arn, "")
}

output "db_cluster_parameter_group_id" {
  description = "The ID of the DB cluster parameter group created"
  value       = try(module.aurora_serverless_v2.db_cluster_parameter_group_id, "")
}

################################################################################
# DB Parameter Group
################################################################################

output "db_parameter_group_arn" {
  description = "The ARN of the DB parameter group created"
  value       = try(module.aurora_serverless_v2.db_parameter_group_arn, "")
}

output "db_parameter_group_id" {
  description = "The ID of the DB parameter group created"
  value       = try(module.aurora_serverless_v2.db_cluster_parameter_group_id, "")
}