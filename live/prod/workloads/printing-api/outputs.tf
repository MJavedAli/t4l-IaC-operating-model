output "ecs_service_arn" {
  description = "Printing API ECS service ARN."
  value       = module.service.service_arn
}

output "task_definition_arn" {
  description = "Printing API task definition ARN."
  value       = module.service.task_definition_arn
}

output "log_group_name" {
  description = "Printing API CloudWatch log group."
  value       = module.service.log_group_name
}
