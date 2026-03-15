# Code Review - 2026-03-15

Scope reviewed:

- `lib/main.dart`
- `supabase/schema.sql`
- `supabase/functions/create-checkout-session/index.ts`
- `supabase/functions/create-billing-portal-session/index.ts`
- `supabase/functions/stripe-webhook/index.ts`
- `test/widget_test.dart`

## Findings

### High

1. Non-atomic child row replacement can lose data on partial failure.
   - Reference: `lib/main.dart:3831`, `lib/main.dart:3846`, `lib/main.dart:3848`, `lib/main.dart:3858`, `lib/main.dart:3868`
   - Why this matters: `saveStudent()` deletes enrollments/awards/activities first, then inserts replacements. Any failure in later inserts leaves the record partially deleted.
   - Recommendation: move save to a transactional RPC or server-side function that updates parent + children in one transaction.

2. Unsaved edits are pushed to parent state before persistence.
   - Reference: `lib/main.dart:902`
   - Why this matters: `StudentDetailPage` calls `onStudentUpdated` on each local edit, even before Save. If save fails or user exits, list state can show unsaved data as if persisted.
   - Recommendation: keep detail edits local until successful save, then emit update to parent.

### Medium

3. Billing redirect URLs are fully client-controlled.
   - Reference: `supabase/functions/create-checkout-session/index.ts:17`, `supabase/functions/create-checkout-session/index.ts:60`, `supabase/functions/create-checkout-session/index.ts:61`, `supabase/functions/create-billing-portal-session/index.ts:17`, `supabase/functions/create-billing-portal-session/index.ts:47`
   - Why this matters: allows arbitrary redirect destinations if a valid authenticated caller sends crafted URLs.
   - Recommendation: enforce an allowlist of origins in edge functions.

4. Stripe customer ID persistence result is ignored.
   - Reference: `supabase/functions/create-checkout-session/index.ts:52`
   - Why this matters: if `profiles` update fails, checkout still proceeds and future portal/webhook linking may break.
   - Recommendation: check update response and fail fast with explicit error.

5. Automated test no longer matches current app entry behavior.
   - Reference: `test/widget_test.dart:13`, `test/widget_test.dart:14`, `lib/main.dart:42`
   - Why this matters: test expects students screen directly, but app now routes through auth gate and Supabase initialization.
   - Recommendation: replace with auth-gate aware tests and repository-mocked widget tests.

## Testing Gaps

- No repository-level tests for serialization + Supabase row mapping.
- No integration tests for save cycle and save failure rollback behavior.
- No tests for billing URL parsing and launch behavior.

## Suggested Immediate Fix Order

1. Fix unsaved edit propagation in `StudentDetailPage`.
2. Make student save transactional (RPC/function approach).
3. Add billing URL allowlist and error handling for profile update.
4. Replace stale widget test with auth-aware tests.
