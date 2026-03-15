# Project Organization Plan

Last updated: 2026-03-15

## Current Pain Points

- Most app logic is in `lib/main.dart` (UI, domain models, repositories, PDF, billing UI).
- Harder to test and reason about isolated features.
- Backend contract knowledge (Supabase + Stripe) is split across README/schema/functions.

## Target Structure (Incremental)

```text
lib/
  app/
    app.dart
    routing/
  features/
    auth/
    students/
      presentation/
      domain/
      data/
    billing/
      presentation/
      data/
    transcript/
      pdf/
  shared/
    models/
    widgets/
    utils/
  env/
    env.dart
```

## Migration Phases

### Phase 1 (Low risk)

- Extract pure data models and mapping helpers from `main.dart`.
- Extract repositories (`StudentRepository`, `ProfileRepository`, `BillingRepository`) to `lib/features/*/data`.
- Keep behavior unchanged.

### Phase 2

- Extract page widgets (`AuthPage`, `StudentsPage`, `StudentDetailPage`, `BillingPage`) into feature folders.
- Keep route wiring centralized in `app/`.

### Phase 3

- Add tests per layer:
  - model mapping tests
  - repository tests
  - widget tests with mocked repositories

## Documentation Conventions

- Keep architecture and state in `docs/CONTEXT_HANDOFF.md`.
- Keep dated reviews in `docs/CODE_REVIEW_YYYY-MM-DD.md`.
- Update this plan whenever folder structure or ownership boundaries change.
