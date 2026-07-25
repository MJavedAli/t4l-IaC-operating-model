locals {
  service_name = "printing-api"

  common_tags = {
    BusinessUnit       = "Printing"
    CostCentre         = var.cost_centre
    DataClassification = var.data_classification
    Environment        = "prod"
    ManagedBy          = "Terraform"
    Owner              = "printing-platform"
    Service            = local.service_name
    Repository         = "raksul-terraform-operating-model"
  }
}

module "service" {
  source = "../../../../modules/ecs-service"

  name               = local.service_name
  cluster_arn        = var.cluster_arn
  container_image    = var.container_image
  container_port     = 8080
  cpu                = 512
  memory             = 1024
  desired_count      = var.desired_count
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  target_group_arn   = var.target_group_arn

  environment = {
    APP_ENV = "production"
    PORT    = "8080"
  }

  # The application policy is intentionally empty in this sample. A real
  # workload should grant only the specific APIs and resources it requires.
  task_role_policy_json = null

  log_retention_days     = 365
  enable_execute_command = false

  tags = local.common_tags
}
