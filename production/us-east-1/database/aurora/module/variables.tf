variable "name" {
  type = string
  description = "Database name"
}

variable "database_engine_configuration" {
  type = object({
    engine = string
    version = string
    family = string
  })
 description = "Database engine, version and family"
}

variable "tags" {
  type = map(string)
  description = "Tags to apply to all resources"
  default = {
    Name = "aurora-serverless-v2"
    Project = "unicorn-rentals"
  }
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "database_subnets" {
  type = list(string)
  description = "Database Subnet IDs"
}

variable "private_subnets_cidr_blocks" {
  type = list(string)
  description = "Private Subnet CIDR Blocks"
}

variable "scaling_configuration" {
  type = object({
    min_capacity = number
    max_capacity = number
  })
  description = "Scaling configuration min and max capacity"
}