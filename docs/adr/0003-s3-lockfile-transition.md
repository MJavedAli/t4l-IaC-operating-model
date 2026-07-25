# ADR 0003: Transition from DynamoDB locking to S3 native lockfiles

- **Status:** Proposed transition
- **Date:** 2026-07-25
- **Owners:** Cloud Infra

## Context

Existing Terraform estates commonly use an S3 backend plus a DynamoDB lock table. Current Terraform supports S3-native lockfiles through `use_lockfile = true`, while DynamoDB-based locking is deprecated. r4l may need compatibility during a staged Terraform upgrade.

## Decision

For new roots, enable S3 native locking. During migration, configure both `use_lockfile = true` and the existing `dynamodb_table` so clients can transition in a controlled window. After every runner and operator uses a compatible Terraform version and no legacy clients remain, remove the DynamoDB setting and retire the table through a separate change.

## Alternatives considered

### Keep DynamoDB indefinitely

Rejected because it preserves an obsolete dependency and operational surface.

### Remove DynamoDB immediately

Rejected because mixed Terraform client versions can undermine safe coordination during migration.

### Move immediately to a managed Terraform platform

Deferred. A managed platform may add value for policy, run orchestration, audit, and private module distribution, but should be selected through an explicit build-versus-buy assessment rather than assumed.

## Consequences

- A temporary period has two locking mechanisms.
- Terraform versions must be inventoried and upgraded.
- Backend migration requires a tested runbook and communication window.
- The DynamoDB table remains protected and monitored until retirement.
