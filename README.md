# transcript_maker

Homeschool transcript builder built with Flutter, preparing for Supabase-backed persistence and Google-authenticated users.

## Development Setup

1. **Install tooling** – Ensure you have Flutter (3.19+) installed and added to your PATH.
2. **Install dependencies** – Run `flutter pub get`.
3. **Configure environment variables**  
   - Copy `.env.example` to `.env` (this file is bundled as an app asset, so Flutter must see it before building).  
   - Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from your Supabase project (these stay local; `.env` is gitignored).

The app bootstraps environment variables via `flutter_dotenv` during `main()` before initializing Supabase.

## Scripts

- `flutter run` – Launch the application on the desired device/emulator.
- `flutter test` – Run the default widget tests.

## Next Steps

- Add Supabase schema migrations (students, enrollments, awards, activities with owner IDs).
- Implement Google OAuth via Supabase Auth.
- Connect Stripe subscriptions for premium features.
