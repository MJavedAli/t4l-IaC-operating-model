# ADR 0002: Isolate Terraform state by deployable capability

- **Status:** Accepted
- **Date:** 2026-07-25
- **Owners:** Cloud Infra

## Context

Large account-level state files create broad blast radius, slow plans, lock contention, difficult ownership, and high-risk recovery. Extremely small states create dependency and operational overhead.

## Decision

Use one state per independently deployable workload or platform capability, scoped by environment/account and region where applicable. State keys follow:

```text
<environment>/<capability-type>/<service>/<region>/terraform.tfstate
```

A root should have one accountable owner and a bounded IAM role. Stable service interfaces are preferred over arbitrary cross-state reads.

## Alternatives considered

### One state per AWS account

Rejected because failure and permission boundaries are too broad for revenue-critical and shared services.

### One state per resource

Rejected because orchestration, dependency management, and operational overhead become excessive.

### Terraform CLI workspaces for prod/nonprod

Rejected as the primary isolation mechanism because explicit directories, accounts, state keys, and IAM roles are easier to audit and automate safely.

## Consequences

- Safer plans and smaller blast radius.
- More roots and backend keys to catalogue.
- Cross-root interfaces require design discipline.
- A changed-root CI mechanism becomes valuable as the repository grows.
