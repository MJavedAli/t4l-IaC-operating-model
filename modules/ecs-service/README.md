# ECS service module

A deliberately small production-shaped ECS/Fargate paved-road module. It creates:

- CloudWatch log group.
- ECS execution and task IAM roles.
- Optional runtime secret access for the execution role.
- ECS task definition.
- ECS service with deployment circuit breaker.
- Optional existing load-balancer target-group attachment.

It intentionally does **not** create networking, ECS clusters, load balancers, autoscaling, alarms, DNS, or application-specific IAM. Those capabilities have different ownership and lifecycle boundaries.

## Usage

```hcl
module "service" {
  source = "../../../../modules/ecs-service"

  name               = "printing-api"
  cluster_arn        = var.cluster_arn
  container_image    = var.container_image
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  target_group_arn   = var.target_group_arn

  tags = {
    BusinessUnit       = "Printing"
    CostCentre         = "PRINT-PLATFORM"
    DataClassification = "Confidential"
    Environment        = "prod"
    ManagedBy          = "Terraform"
    Owner              = "printing-platform"
    Service            = "printing-api"
  }
}
```

## Versioning

The module follows semantic versioning. Monorepo release tags use `modules/ecs-service/vX.Y.Z`. External consumers should use a private registry or Git source pinned to a released tag. Breaking changes require a major release and migration notes.

## Operational notes

- Pin container images by digest for production.
- Keep `assign_public_ip = false`.
- Grant application IAM through a narrowly scoped policy.
- ECS Exec remains disabled by default and requires audited access controls.
- Add service-specific alarms, SLOs, autoscaling, and runbooks in the owning workload root or adjacent modules.
