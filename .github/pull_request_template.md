## Summary

<!-- What changes, and why is it needed? -->

## Scope

- Terraform roots/modules changed:
- AWS accounts/regions affected:
- Business services affected:
- Related ticket/incident/ADR:

## Risk assessment

- [ ] No production impact expected
- [ ] Production behaviour changes
- [ ] Security or IAM change
- [ ] Data migration/state operation
- [ ] Cost increase is possible
- [ ] Revenue-critical printing path is affected

**Failure modes and blast radius:**

## Terraform plan

<!-- The workflow will post the plan. Summarise important create/update/destroy actions here. -->

- Creates:
- Updates:
- Destroys/replaces:
- Expected monthly cost change:

## Rollout and rollback

**Rollout steps:**

**Validation signals:**

**Rollback/recovery plan:**

## Operational readiness

- [ ] Monitoring/alerts are updated
- [ ] Runbook is updated
- [ ] Ownership and tags are correct
- [ ] Capacity and quotas are checked
- [ ] Backup/restore or rollback is tested where relevant
- [ ] Elastic Infra/SRE/product on-call impact is understood

## Checklist

- [ ] `make check` passes locally
- [ ] No secrets or sensitive values are committed
- [ ] Module or ADR documentation is updated where needed
- [ ] Change is backward compatible, or a migration plan is included
- [ ] Policy exceptions include owner, rationale, compensating control, and expiry
- [ ] Production change window and approvers are identified
