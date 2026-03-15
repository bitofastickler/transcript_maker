# Release Log

Last updated: 2026-03-15

## Purpose

Track only shipped/tested releases and rollout-impacting notes.
Do not add routine dev activity here.

## Entry Format

- Date (YYYY-MM-DD)
- Platform/track
- Version/build
- What changed (1-3 bullets)
- Result (released, rolled back, superseded)

## Entries

### 2026-03-15

- Platform/track: docs process update
- Version/build: n/a
- What changed:
  - Added lightweight docs recovery workflow (`INDEX`, `STATUS`, `DECISIONS`, `CONTEXT_HANDOFF`).
- Result: active

### 2026-03-15

- Platform/track: web (Render deployment)
- Version/build: main @ 592e34d
- What changed:
  - Moved student-detail save control into top app bar.
  - Kept bottom unsaved panel informational-only to reduce save-button blocking/visibility issues.
- Result: deployed; pending additional tester verification

### 2026-03-15

- Platform/track: web + billing integration
- Version/build: main @ 12e8d93
- What changed:
  - Aligned billing portal client invoke name to deployed Supabase function (`create-billing-portal-session`).
  - Updated setup/handoff docs to match Supabase billing portal deployment contract.
- Result: deployed

### 2026-03-15

- Platform/track: web (Render deployment)
- Version/build: main @ 74dff5f
- What changed:
  - Replaced default Flutter tab icon and PWA icon assets with project logo.
  - Updated `web/index.html` and `web/manifest.json` branding labels.
- Result: deployed; browser cache refresh may be required for favicon visibility
