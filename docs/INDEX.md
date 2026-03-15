# Docs Index

Last updated: 2026-03-15

## Read Order For New Session

1. `docs/CONTEXT_HANDOFF.md` (fast snapshot + recovery)
2. `docs/STATUS.md` (what is done, blocked, next)
3. `docs/RELEASE_LOG.md` (what was shipped/tested and current rollout state)
4. `docs/CODE_REVIEW_2026-03-15.md` (known technical risks)
5. `docs/ORGANIZATION_PLAN.md` (refactor direction)
6. `README.md` (setup + deployment details)

## Document Roles

- `CONTEXT_HANDOFF.md`
  - short architecture/operations summary
  - first file to read after context reset
- `STATUS.md`
  - current phase, blockers, and next execution steps
  - operational heartbeat for owner + future agent sessions
- `CODE_REVIEW_2026-03-15.md`
  - point-in-time code review findings and severity
- `ORGANIZATION_PLAN.md`
  - intended target structure and migration phases
- `DECISIONS.md`
  - durable architectural/product decisions with rationale
- `RELEASE_LOG.md`
  - release history for internal/prod tracks and rollout-impacting outcomes

## Update Protocol

When making meaningful changes:

1. Update `STATUS.md`:
   - move completed items
   - refresh blockers and next 1-3 tasks
   - bump "Last updated"
2. If architecture changes, update:
   - `CONTEXT_HANDOFF.md`
   - `DECISIONS.md` (add new decision entry)
3. If new risks are found, append or create dated review file.

## Principle

Keep these docs short and operational. Prefer current status and explicit decisions over long narrative history.
