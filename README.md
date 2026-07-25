# R4L Terraform Operating Model

> **Purpose:** demonstrate a small, end-to-end Terraform operating model for an AWS-centric, multi-account organisation. This repository is an assessment artefact, not r4l production code.

## 1. Purpose

This repository shows how a new Cloud Infrastructure team can provide safe, reusable infrastructure capabilities without becoming a central ticket queue. It contains one complete vertical slice: a reusable ECS/Fargate service module consumed by a production `printing-api` live root, with state isolation, CI controls, policy checks, ownership metadata, and drift detection.

The design assumes:

- AWS is the primary cloud and Terraform is the default IaC tool.
- Existing EC2 and ECS estates must be evolved incrementally rather than rewritten at once.
- Product teams need paved roads and clear ownership boundaries.
- The Cloud Infra team will remain small while the engineering organisation grows toward 300 people.
- English is the default language for code, documentation, ADRs, and reviews.

## 2. Scope and non-goals

### In scope

- A hybrid repository operating model.
- Reusable module and live-root separation.
- Per-workload state isolation.
- GitHub Actions examples using AWS OIDC federation.
- Pull-request plans, production approvals, policy checks, and drift detection.
- A production-shaped ECS service module.
- Governance examples: CODEOWNERS, ADRs, PR template, tags, and ownership boundaries.

### Non-goals

- A complete AWS landing zone or Control Tower implementation.
- Every network, identity, observability, security, and backup resource.
- Automatic migration of legacy EC2 workloads.
- A mandatory Kubernetes platform.
- A complete 24/7 operating model or incident-management implementation.
- A copy-paste deployment into an unknown AWS organisation.

## 3. Architecture principles

1. **Business criticality drives controls.** Printing, identity, and payment changes receive stronger review and rollout controls than sandboxes.
2. **Small states and explicit ownership reduce blast radius.** Each independently deployable workload or platform capability has a separate root and state key.
3. **Paved roads, not central tickets.** Product teams consume versioned modules and workflows; Cloud Infra owns standards and high-risk foundations.
4. **Progressive standardisation.** Acquired companies first reach a minimum security and operability baseline, then migrate toward group standards based on risk and value.
5. **No big-bang rewrite.** Existing Terraform is adopted, measured, and improved unless replacement has a clear business case.
6. **Plans are review artefacts.** Production applies must be traceable to reviewed code and an immutable commit.
7. **Credentials are short-lived.** CI uses GitHub OIDC to assume least-privilege AWS roles; no long-lived AWS keys are stored in GitHub.
8. **Policy violations are actionable.** Mandatory controls block changes; advisory checks create visible feedback without freezing delivery.
9. **Exceptions expire.** Any policy exception needs an owner, reason, compensating control, and review date.
10. **English-first asynchronous operations.** Decisions are captured in ADRs and runbooks so Japan, India, and Vietnam can collaborate across time zones.

## 4. Repository model

This sample uses a **hybrid monorepo**:

- `modules/` contains centrally maintained, broadly reusable modules.
- `live/` contains small root modules representing deployable units.
- `policies/`, workflows, and governance files are shared.
- Very large or independently governed products can later move their live roots to product repositories while consuming released central modules.

Why not one repository forever? A single repository simplifies discovery and bootstrapping, but can eventually create noisy reviews and broad access. Why not polyrepo immediately? With a new 5–10-person Cloud Infra team, premature fragmentation increases duplicated pipelines and inconsistent controls. The hybrid model starts simple and establishes an explicit extraction path.

## 5. Directory structure

```text
.
├── .github/
│   ├── pull_request_template.md
│   └── workflows/
│       ├── terraform-apply.yml
│       ├── terraform-ci.yml
│       ├── terraform-drift.yml
│       └── terraform-plan.yml
├── backend/
│   └── prod-printing-api.hcl.example
├── docs/
│   ├── adr/
│   │   ├── 0001-hybrid-repository-model.md
│   │   ├── 0002-state-isolation.md
│   │   └── 0003-s3-lockfile-transition.md
│   └── architecture.md
├── live/
│   └── prod/
│       └── workloads/
│           └── printing-api/
│               ├── backend.tf
│               ├── main.tf
│               ├── outputs.tf
│               ├── providers.tf
│               ├── terraform.tfvars.example
│               ├── variables.tf
│               └── versions.tf
├── modules/
│   └── ecs-service/
│       ├── CHANGELOG.md
│       ├── README.md
│       ├── main.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── versions.tf
├── policies/
│   └── terraform.rego
├── scripts/
│   ├── bootstrap-backend.sh
│   ├── list-terraform-directories.sh
│   └── validate-all.sh
├── .gitignore
├── .pre-commit-config.yaml
├── .tflint.hcl
├── CODEOWNERS
├── Makefile
└── README.md
```

## 6. State isolation strategy

State is isolated by:

- AWS environment/account.
- Capability type (`platform`, `shared-service`, or `workload`).
- Product or service.
- Region when a service is regional.

Example state key:

```text
prod/workloads/printing-api/ap-northeast-1/terraform.tfstate
```

A state should normally contain one independently deployable capability owned by one team. It should not contain an entire AWS account. This limits lock contention, narrows IAM permissions, improves plan readability, and reduces the impact of an erroneous apply.

Cross-state dependencies should prefer stable interfaces such as SSM Parameter Store, AWS Resource Explorer/tag discovery, or a service catalogue. Direct `terraform_remote_state` usage is reserved for tightly controlled platform roots because it grants access to the entire state snapshot.

## 7. Environment and AWS account mapping

The following values are illustrative and must be replaced:

| Environment | Example AWS account | Purpose | Apply authority |
|---|---:|---|---|
| `management` | `111111111111` | AWS Organizations and billing | Cloud Infra leads only |
| `security` | `222222222222` | Security tooling and delegated administration | Cloud Infra + Security |
| `log-archive` | `333333333333` | Immutable central logs | Cloud Infra + Security |
| `shared-services` | `444444444444` | CI, DNS, artefacts, observability | Cloud Infra/SRE |
| `prod-printing` | `555555555555` | Revenue-critical printing workloads | Approved product + Cloud Infra owners |
| `nonprod-printing` | `666666666666` | Development, QA, staging | Delegated product owners |
| `sandbox` | `777777777777` | Time-bound experimentation | Engineers with guardrails |
| `acquisition-quarantine` | `888888888888` | Initial M&A assessment and containment | Cloud Infra + Security |

Accounts should be separated primarily by security boundary, billing/ownership, and failure domain—not merely because another environment exists.

## 8. Development workflow

1. Create a short-lived branch.
2. Run `make check` locally.
3. Update or add an ADR when the change introduces a durable architectural decision.
4. Open a pull request using the template.
5. CI runs formatting, validation, linting, and static security checks.
6. For live-root changes, the plan workflow assumes a read/plan role using OIDC and comments the plan on the PR.
7. CODEOWNERS and branch protection require the relevant product and Cloud Infra reviewers.
8. Merge to `main` only after the plan, policy checks, and risk/rollback review are accepted.
9. The production apply job targets the protected `production` GitHub Environment and requires a human reviewer.
10. The workflow replans at the exact merged commit and applies that saved plan.

Direct local production applies are break-glass only, separately logged, and followed by reconciliation through Git.

## 9. CI/CD workflow

| Workflow | Trigger | Purpose |
|---|---|---|
| `terraform-ci.yml` | Pull request and push | `fmt`, `init -backend=false`, `validate`, TFLint, and Trivy configuration scanning |
| `terraform-plan.yml` | Pull request affecting `printing-api` | OIDC authentication, backend init, plan, Conftest policy evaluation, PR comment |
| `terraform-apply.yml` | Merge/push to `main` or manual dispatch | Replan, policy check, protected production approval, exact-plan apply |
| `terraform-drift.yml` | Nightly and manual | Detailed-exit-code plan and GitHub issue creation when drift is found |

The sample intentionally targets one root. At scale, a changed-root detector or orchestration layer should generate a bounded matrix rather than running every root.

## 10. Production approval controls

Repository settings—not YAML alone—must enforce:

- Protected `main` branch.
- Required status checks.
- Required CODEOWNERS reviews.
- No direct pushes.
- Signed commits where organisational policy requires them.
- A `production` GitHub Environment with required reviewers and branch restrictions.
- Separate AWS IAM roles for plan and apply.
- An apply-role trust policy restricted to this repository, branch, workflow, and GitHub environment.
- CloudTrail logging and alerting for privileged role assumptions.

GitHub Environment reviewers provide the manual gate. AWS IAM remains the final enforcement boundary.

## 11. Module ownership and versioning

- Each module has an owning team in `CODEOWNERS`, a README, examples or tests, and a changelog.
- Semantic versioning is used for externally consumed modules.
- In this bootstrap monorepo, live roots use local paths so one PR can demonstrate a vertical slice.
- Release tags follow `modules/<name>/vMAJOR.MINOR.PATCH`, for example `modules/ecs-service/v1.2.0`.
- Once consumers exist outside this repository, CI publishes the module to a dedicated module repository or private registry. Consumers pin an exact release constraint; they do not follow `main`.
- Breaking changes require a major version, migration guide, and supported overlap period.
- Provider dependency lock files are committed per root after initialisation in the real repository. This sample omits generated lock files to stay platform-neutral.

## 12. Security and policy enforcement

The sample layers controls:

1. Terraform type validation and preconditions.
2. TFLint for Terraform/AWS correctness.
3. Trivy configuration scanning for common misconfigurations.
4. Conftest/OPA against Terraform plan JSON for organisation-specific rules.
5. CODEOWNERS and branch protection.
6. AWS OIDC roles with scoped IAM permissions.
7. AWS-native controls such as SCPs, Config, CloudTrail, GuardDuty, Security Hub, and KMS outside this sample.

`policies/terraform.rego` demonstrates mandatory tags and blocking public S3 settings. In production, policy bundles should be versioned, tested, and divided into deny, warn, and audit-only tiers.

Secrets must be referenced from AWS Secrets Manager or SSM Parameter Store. Secret values must not be stored in Terraform variables, Git, plan output, or state when a runtime reference is possible.

## 13. Drift management

- Nightly plans detect changes outside Terraform.
- Drift opens or updates a GitHub issue; it does not automatically overwrite production.
- The owner classifies drift as authorised emergency change, benign provider/API normalisation, or unauthorised mutation.
- The remediation is either import/configuration update or controlled reversion.
- Repeated drift is treated as an ownership or access-control problem, not merely a tooling problem.
- Emergency console changes require an incident/change reference and a reconciliation pull request.

## 14. Disaster recovery for Terraform state

The backend bootstrap example enables:

- S3 versioning.
- KMS encryption.
- Public-access blocking.
- DynamoDB point-in-time recovery for the transitional lock table.
- S3 native lockfiles for current Terraform versions.

The production design should additionally include:

- Cross-account, cross-region S3 replication to a recovery bucket.
- Restricted recovery roles and a tested state-restore runbook.
- CloudTrail data events for the state bucket.
- Periodic restore exercises using a non-production root.
- Retention and deletion controls aligned with security and legal requirements.

State recovery must be a deliberate operation. Replicated state is not automatically promoted; the backend configuration and IAM controls are switched through an approved recovery procedure.

## 15. Ownership boundaries

| Area | Cloud Infra | Product teams | Elastic Infra | SRE | Security/Finance |
|---|---|---|---|---|---|
| AWS organisation, account vending, SCPs | Accountable | Consulted | Consulted | Consulted | Security consulted |
| Core modules and policies | Accountable | Contributors/consumers | Contributors | Contributors | Security consulted |
| Product workload configuration | Consulted/approver for high risk | Accountable | Transitional support | Reliability consultation | As required |
| Printing production operations | Increasing accountability during transition | Service accountability | Current operational owner, gradually transferring | Observability/incident support | Business risk visibility |
| M&A baseline migration | Standards/accountability | Product input | Responsible for migration execution | Operability input | Security gate |
| Cost allocation and optimisation | Platform controls | Workload actions | Operational input | Efficiency signals | Finance accountable for reporting model |

Ownership is transferred capability by capability with entry/exit criteria, not by an arbitrary date.

## 16. How application teams consume infrastructure capabilities

Application teams should normally:

- Instantiate a reviewed module through a small live root.
- Supply product-owned values: service name, image, sizing, scaling intent, environment references, and ownership tags.
- Receive automated plan and policy feedback in the pull request.
- Own service-level alarms, runbooks, deployment safety, and cost decisions within defined guardrails.

Cloud Infra owns account foundations, high-risk shared services, module quality, policy, CI templates, privileged roles, and the service catalogue. Exceptions are handled through a lightweight ADR/request with expiry rather than an unstructured ticket queue.

## 17. Acquired-company onboarding

Use a staged model:

1. **Discover:** inventory accounts, access, spend, data classification, dependencies, incidents, and undocumented operations.
2. **Contain:** central identity federation, root-account protection, logging, security monitoring, backups, budget alerts, and critical ownership contacts.
3. **Stabilise:** minimum availability, patching, recovery, observability, tagging, and IaC baselines.
4. **Standardise selectively:** adopt group modules and account structure where risk/value justify migration.
5. **Optimise:** cost, developer self-service, resilience, and product-aligned ownership.

Acquisitions are not forced into the target architecture before business continuity and knowledge transfer are secured.

## 18. Local setup

Required tools:

- Terraform `~> 1.15.0` (CI is configured to use Terraform 1.15.8).
- AWS CLI v2.
- TFLint.
- Trivy.
- Conftest.
- pre-commit.
- GNU Make.

```bash
pre-commit install
make check
```

For a real plan:

```bash
cp live/prod/workloads/printing-api/terraform.tfvars.example \
  live/prod/workloads/printing-api/terraform.tfvars
cp backend/prod-printing-api.hcl.example backend/prod-printing-api.hcl

# Replace all illustrative values first.
make init ROOT=live/prod/workloads/printing-api \
  BACKEND_CONFIG=../../../../backend/prod-printing-api.hcl
make plan ROOT=live/prod/workloads/printing-api
```

Authentication should use AWS IAM Identity Center locally and OIDC in CI.

## 19. Example commands

```bash
make fmt
make validate
make lint
make security
make check
make init ROOT=live/prod/workloads/printing-api BACKEND_CONFIG=../../../../backend/prod-printing-api.hcl
make plan ROOT=live/prod/workloads/printing-api
make policy ROOT=live/prod/workloads/printing-api
```

`make apply` is intentionally not the default path for production. Production applies should run through the protected workflow.

## 20. Roadmap and known limitations

### 0–6 months

- Inventory and adopt existing Terraform.
- Establish account/state ownership, OIDC roles, branch protections, and production change controls.
- Pilot the paved road with one non-critical service, then one printing workload.
- Define tagging, cost allocation, security baselines, and operational readiness criteria.

### 6–18 months

- Expand module catalogue and self-service templates.
- Add changed-root orchestration, module tests, ephemeral integration environments, and central policy distribution.
- Complete capability-based transfer from Elastic Infra for agreed printing and group functions.
- Implement M&A landing and stabilisation playbooks.

### 18–36 months

- Product-aligned ownership for most workload roots.
- Automated account vending and service catalogue integration.
- Mature FinOps allocation, reliability scorecards, and cross-region recovery exercises.
- Extract high-volume live roots or modules into independently governed repositories where justified.

### Known limitations of this sample

- Existing VPC, ECS cluster, security groups, and target groups are passed as variables rather than provisioned.
- IAM permissions are deliberately minimal and need workload-specific policies.
- Autoscaling, alarms, WAF, DNS, certificates, service discovery, deployment strategies, and backup resources are omitted.
- GitHub organisation settings, AWS OIDC provider resources, and IAM trust policies are described but not created.
- The bootstrap script uses placeholder names and is not idempotent across every partition/region scenario.
- CI workflows target one live root rather than dynamically discovering all changed roots.
- Action major tags are used for readability; a production repository should pin third-party actions and container images to reviewed immutable digests/commit SHAs.

## Executability classification

| Area | Classification | Notes |
|---|---|---|
| Terraform module syntax | Executable-oriented sample | Run `make check` before use; this delivery environment did not include the Terraform CLI |
| Live root | Executable after configuration | Requires real AWS IDs, backend, OIDC/IAM, and workload inputs |
| CI workflows | Illustrative production pattern | Requires repository variables, environments, branch protection, and AWS roles |
| Backend bootstrap | Illustrative | Review naming, KMS, replication, retention, and break-glass requirements first |
| OPA policy | Executable-oriented example | Run Conftest against a real plan JSON; expand tests and exception handling before broad enforcement |
| Account IDs, ARNs, bucket names | Illustrative | Must be replaced |

##  Discussion points

This repository intentionally makes trade-offs visible: monorepo simplicity versus future autonomy, local module references versus released versions, S3 lockfile migration versus existing DynamoDB locks, product self-service versus central controls, and gradual adoption versus greenfield purity.
