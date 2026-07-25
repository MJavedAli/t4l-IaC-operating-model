# ADR 0001: Adopt a hybrid Terraform repository model

- **Status:** Accepted for initial target state
- **Date:** 2026-07-25
- **Owners:** Cloud Infra and Platform Architecture

## Context

RAKSUL needs common AWS and Terraform standards while a small Cloud Infra team supports many product teams, legacy printing infrastructure, group-wide services, and M&A environments. A pure monorepo can become noisy and over-centralised; immediate polyrepo adoption duplicates pipelines and governance before stable boundaries exist.

## Decision

Start with a hybrid monorepo containing central modules, policies, workflows, and selected live roots. Permit product-owned live repositories when a product has clear ownership, sufficient operational maturity, and a justified need for independent delivery. External consumers use released module versions rather than repository-relative paths.

## Alternatives considered

### One permanent monorepo

- **Benefits:** easy discovery, atomic changes, one control plane.
- **Rejected as a permanent rule because:** access, review volume, and delivery coupling may become problematic at 300 engineers.

### Polyrepo from day one

- **Benefits:** autonomy and narrow access.
- **Rejected initially because:** pipeline duplication, inconsistent policies, and module-release overhead would burden a new team.

### Terraform workspaces as the primary environment boundary

- **Benefits:** fewer directories.
- **Rejected because:** workspace selection is an implicit operational context and does not provide the account/state ownership clarity required for production boundaries.

## Consequences

- Initial onboarding is simple and discoverable.
- CODEOWNERS and path-based workflows become important.
- Local module references are acceptable only inside the bootstrap repository.
- Extraction criteria and versioned module releases must be established before repository size becomes a bottleneck.
