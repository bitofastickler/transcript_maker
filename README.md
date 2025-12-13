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

## Next Steps

- Implement the Supabase data repository & replace `SampleData` with real queries.
- Add Google OAuth UI using `supabase.auth.signInWithOAuth`.
- Integrate Stripe subscriptions and gate premium features using the `profiles` table.
