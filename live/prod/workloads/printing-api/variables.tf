variable "aws_region" {
  description = "AWS region for the workload."
  type        = string
  default     = "ap-northeast-1"
}

variable "cluster_arn" {
  description = "Existing production ECS cluster ARN."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs across at least two availability zones."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for printing-api tasks."
  type        = list(string)
}

variable "target_group_arn" {
  description = "Existing target group ARN. Null supports a non-load-balanced demonstration."
  type        = string
  default     = null
  nullable    = true
}

variable "container_image" {
  description = "Immutable printing-api image reference."
  type        = string
}

variable "desired_count" {
  description = "Baseline number of production tasks."
  type        = number
  default     = 2
}

variable "cost_centre" {
  description = "Finance-approved cost-centre code."
  type        = string
  default     = "PRINT-PLATFORM"
}

variable "data_classification" {
  description = "Group data-classification label."
  type        = string
  default     = "Confidential"
}
