# Architecture Decisions

Last updated: 2026-03-15

## ADR-001: Supabase As Primary Backend

- Status: accepted
- Date: 2026-03-15
- Decision:
  - Use Supabase Auth + Postgres + RLS as the system of record for student data.
- Rationale:
  - rapid backend setup
  - native auth integration for Flutter
  - owner-scoped security policies at data layer
- Consequences:
  - app must always provide `owner_id` on writes
  - schema/policy compatibility is critical to runtime behavior

## ADR-002: Stripe Managed Through Supabase Edge Functions

- Status: accepted
- Date: 2026-03-15
- Decision:
  - Keep Stripe secret usage server-side in Supabase Edge Functions.
- Rationale:
  - prevent exposing Stripe secret in client
  - centralize subscription state sync into `profiles`
- Consequences:
  - function secrets and webhook reliability are release-critical
  - billing status in app depends on profile updates from webhook flow

## ADR-003: Single-File App During Early Build Phase

- Status: temporary
- Date: 2026-03-15
- Decision:
  - Keep major app logic in `lib/main.dart` until launch stabilization.
- Rationale:
  - optimize feature velocity and reduce early-file churn
- Consequences:
  - testing and ownership boundaries are weaker
  - refactor is planned in phases (see `docs/ORGANIZATION_PLAN.md`)

## ADR-004: Academic-Year Grouping Instead Of Term-Name Workflow

- Status: accepted
- Date: 2026-03-15
- Decision:
  - Organize classes by academic year and grade level, not user-entered term names.
- Rationale:
  - simpler data entry
  - better consistency for transcript output
- Consequences:
  - UI, grouping logic, and sample data align around `yearLabel` and `gradeLevel`

## How To Add A New Decision

Use the next incremental ADR number and include:

1. status
2. date
3. decision statement
4. rationale
5. consequences
