# Project Status

Last updated: 2026-03-15

## Current Phase

Launch hardening on Supabase-backed architecture with internal Play testing active.

## Completed

- Android release signing configured and app bundle build succeeds.
- Package/application id moved off `com.example`.
- Launcher icon pipeline wired with `flutter_launcher_icons`.
- Domain model updated to group classes by academic year (no term-name workflow).
- Supabase schema and edge function scaffolding present in repo.
- Billing UI and Stripe function integration wired in app.

## In Progress

- Documentation hardening for context recovery.
- Backend architecture clarification and operational runbook quality.

## Open Risks / Blockers

- Student aggregate save path is non-transactional when replacing child rows.
- Unsaved edits can be reflected upstream before persistence succeeds.
- Billing edge functions accept caller-provided return URLs without allowlist checks.
- Test suite does not yet cover current auth-gated app behavior and repository flows.

## Next Actions (Priority Order)

1. Refactor `StudentDetailPage` edit propagation so parent list is only updated after successful save.
2. Replace delete-and-reinsert save strategy with transactional server-side save (RPC/Edge function).
3. Add allowlist validation for checkout/portal return URLs in edge functions.
4. Replace stale widget test with auth-aware and repository-mocked tests.
5. Continue modularizing `lib/main.dart` according to `docs/ORGANIZATION_PLAN.md`.

## Release Readiness Snapshot

- Android internal testing: active
- Data persistence: enabled via Supabase
- Billing subscription path: wired, requires secure production config and webhook validation
- Test confidence: low to medium until critical tests are added

## Verification Checklist

Run before each release candidate:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build appbundle --release`
5. Smoke test internal track build (auth, CRUD, PDF export, billing entry points)
