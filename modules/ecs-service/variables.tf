variable "name" {
  description = "Stable service name used for AWS resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,39}$", var.name))
    error_message = "name must be 3-40 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "cluster_arn" {
  description = "ARN of an existing ECS cluster."
  type        = string
}

variable "container_image" {
  description = "Immutable container image reference, preferably an ECR digest."
  type        = string
}

variable "container_port" {
  description = "Application container port."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired ECS service task count."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1 for this production-oriented module."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs used by ECS tasks."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnets are required to demonstrate multi-AZ placement."
  }
}

variable "security_group_ids" {
  description = "Security groups attached to ECS tasks."
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) >= 1
    error_message = "At least one security group is required."
  }
}

variable "assign_public_ip" {
  description = "Whether ECS tasks receive public IPs. This should normally remain false."
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "Optional existing ALB/NLB target group ARN."
  type        = string
  default     = null
  nullable    = true
}

variable "environment" {
  description = "Non-sensitive environment variables supplied to the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of container environment variable names to Secrets Manager or SSM parameter ARNs."
  type        = map(string)
  default     = {}
}

variable "command" {
  description = "Optional container command override."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
  default     = 90
}

variable "enable_execute_command" {
  description = "Enable ECS Exec. Requires separate audited access controls."
  type        = bool
  default     = false
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy task percentage during deployments."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum task percentage during deployments."
  type        = number
  default     = 200
}

variable "health_check_grace_period_seconds" {
  description = "Load balancer health-check grace period."
  type        = number
  default     = 60
}

variable "task_role_policy_json" {
  description = "Optional IAM policy JSON attached to the application task role."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Mandatory group tags."
  type        = map(string)

  validation {
    condition = alltrue([
      for key in [
        "BusinessUnit",
        "CostCentre",
        "DataClassification",
        "Environment",
        "ManagedBy",
        "Owner",
        "Service"
      ] : contains(keys(var.tags), key) && trimspace(var.tags[key]) != ""
    ])
    error_message = "tags must contain non-empty BusinessUnit, CostCentre, DataClassification, Environment, ManagedBy, Owner, and Service values."
  }
}
