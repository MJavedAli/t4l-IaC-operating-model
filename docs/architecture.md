# Conceptual architecture

```mermaid
flowchart TB
  Dev[Product or Cloud Infra engineer] --> PR[GitHub pull request]
  PR --> CI[fmt / validate / TFLint / Trivy]
  PR --> Plan[OIDC plan workflow]

  subgraph GitHub[GitHub control plane]
    CI
    Plan --> Policy[OPA / Conftest]
    Policy --> Review[CODEOWNERS + required checks]
    Review --> Main[Protected main branch]
    Main --> Env[Protected production environment]
  end

  Env --> Apply[OIDC apply workflow]

  subgraph AWS[AWS organisation]
    Apply --> Role[Scoped Terraform apply role]
    Plan --> ReadRole[Scoped Terraform plan role]
    Role --> Workload[Production printing account]
    ReadRole --> Workload
    Role --> State[(S3 state + native lockfile)]
    ReadRole --> State
    State -. transition .-> DDB[(DynamoDB lock table)]
    State -. replication .-> DR[(Recovery account/region)]
  end

  Module[Versioned ECS service module] --> Live[Small printing-api live root]
  Live --> Plan
  Policies[Central policy bundle] --> Policy
  Drift[Nightly refresh-only plan] --> Issue[Owner-visible drift issue]
  Workload --> Drift
```

## Control-plane boundaries

- GitHub determines review and workflow orchestration.
- AWS IAM determines whether a workflow can read or change infrastructure.
- Terraform state is isolated per deployable root.
- Product teams own workload intent and service operations.
- Cloud Infra owns the paved road, privileged roles, shared policy, and foundations.
- Security and finance requirements are encoded as guardrails and feedback, not hidden review queues.
