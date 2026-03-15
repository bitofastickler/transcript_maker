# Transcript Maker Context Handoff

Last updated: 2026-03-15

## Purpose

This is the fast-recovery page for future sessions. If context is reset, read this file first, then `docs/INDEX.md`.

## 60-Second Snapshot

- Product: Homeschool Transcript Maker.
- Frontend: Flutter app, still largely consolidated in `lib/main.dart`.
- Backend: Supabase (Auth + Postgres + RLS).
- Billing: Stripe via Supabase Edge Functions.
- Active release path: Google Play internal testing.

## Runtime Design (High Level)

### App bootstrap

- `main()` loads env via `AppEnv`, initializes Supabase, and creates:
  - `StudentRepository`
  - `ProfileRepository`
  - `BillingRepository`

### Auth flow

- `AuthGate` checks session.
- No session -> `AuthPage` (Google OAuth).
- Session -> `StudentsPage`.

### Data flow

- `StudentsPage` loads/saves/deletes student aggregates through `StudentRepository`.
- `StudentDetailPage` edits local student model, then persists via explicit save.
- PDF export is generated client-side (`TranscriptPdfService`).

### Backend contract

- Schema source of truth: `supabase/schema.sql`
- App tables:
  - `profiles`
  - `students`
  - `enrollments`
  - `awards`
  - `activities`
- Ownership model:
  - every data row carries `owner_id`
  - RLS policies enforce owner-only access
  - trigger guard enforces child row ownership against parent student

### Billing contract

- `create-checkout-session`: creates/reuses Stripe customer and returns checkout URL.
- `create-billing-portal-session`: returns Stripe customer portal URL.
- `stripe-webhook`: writes subscription state into `profiles`.
- Client billing portal navigation invokes `create-billing-portal-session`.
- Keep local function folder name aligned with deployed function name for CLI redeploys.

Portal function request/response contract:
- URL: `https://<project-ref>.supabase.co/functions/v1/create-billing-portal-session`
- Method: `POST`
- Headers:
  - `Authorization: Bearer <access_token>`
  - `Content-Type: application/json`
- Body: `{ "return_url": "https://your.app/account" }`
- Response: `{ "url": "https://billing.stripe.com/session/..." }`

## Environment Keys

### App (`.env` or Dart defines)

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `STRIPE_PRICE_ID` (required for subscribe action)

### Supabase Edge Function secrets

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_TRIAL_DAYS` (optional, defaults to `30`)
- `STRIPE_WEBHOOK_SECRET`

## Current Risk Summary

Detailed findings live in `docs/CODE_REVIEW_2026-03-15.md`.

- save path for child rows is not transactional
- unsaved detail edits currently update parent list state
- billing redirect URLs are client-controlled (no allowlist)
- widget tests are outdated for auth-gated runtime

## Recovery Checklist

1. Read `docs/INDEX.md` and `docs/STATUS.md`.
2. Check `docs/RELEASE_LOG.md` for current rollout state.
3. Validate local setup:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
4. Verify backend config:
   - Supabase schema aligned with `supabase/schema.sql`
   - Edge function secrets present
   - Billing/portal function names aligned between app invoke target and deployed Supabase functions
5. For release work:
   - build signed bundle
   - upload to internal track first

## Backend Facts To Keep Updated

- Production Supabase project ref:
- Production web domain:
- OAuth redirect URLs:
- Stripe product and price IDs:
- Stripe webhook endpoint:
- Any intentional architecture deviations:
