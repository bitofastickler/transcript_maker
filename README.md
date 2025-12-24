# transcript_maker

Homeschool transcript builder built with Flutter, preparing for Supabase-backed persistence and Google-authenticated users.

## Development Setup

1. **Install tooling** - Ensure you have Flutter (3.19+) installed and added to your PATH.
2. **Install dependencies** - Run `flutter pub get`.
3. **Configure environment variables**  
   - Copy `.env.example` to `.env` (this file is bundled as an app asset, so Flutter must see it before building).  
   - Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from your Supabase project (these stay local; `.env` is gitignored).

The app bootstraps environment variables via `flutter_dotenv` during `main()` before initializing Supabase.

## Supabase Setup

1. Create a Supabase project and add its URL/key to `.env`.
2. In the Supabase dashboard, open **SQL Editor → New query**, paste `supabase/schema.sql`, and run it.  
   - This creates the `profiles`, `students`, `enrollments`, `awards`, and `activities` tables plus owner-scoped Row Level Security policies.  
   - When inserting from the app, always set `owner_id = supabase.auth.currentUser!.id` so policies pass.
3. Enable the Google OAuth provider (Auth → Providers) once you have Google Cloud credentials.
4. Optional: connect Stripe via Supabase's Payments extension so the `profiles` subscription fields stay in sync.

## Scripts

- `flutter run` - Launch the application on the desired device/emulator.
- `flutter test` - Run the default widget tests.

## Current Status

- Supabase schema (tables + RLS) is live, and the Flutter app now loads/saves students, enrollments, awards, and activities through a repository layer instead of `SampleData`.
- Google OAuth is enabled in Supabase, and the app gates access behind the `signInWithOAuth` flow (web/desktop works out-of-the-box; mobile just needs platform-specific deep links).
- Local analyzer/test runs succeed once Supabase is initialized; remaining blockers are purely deployment-related.

## Next Steps

- Build the Flutter web bundle (`flutter build web`) and deploy it to a Render static site (or another host).
- Add the Render domain to Google OAuth Authorized JavaScript origins and Supabase Auth redirect settings, then smoke-test sign-in + saving end-to-end.
- Once hosting is stable, expand coverage (widget tests, auth guards, premium gating via the `profiles` table/Stripe) as needed.
