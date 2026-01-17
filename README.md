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
4. Set **Auth ƒ+' URL Configuration**:
   - **Site URL**: your production web domain (Render URL).  
   - **Redirect URLs**: add your production domain plus any local dev URLs you use.

## Stripe Billing Setup (Supabase + Edge Functions)

The app calls two Supabase Edge Functions to create Stripe sessions. You must deploy them and configure secrets.

1. **Create a Stripe product + price**  
   - Use Stripe Dashboard to create your annual subscription price.  
   - Copy the price ID (looks like `price_...`).

2. **Set app config**  
   - Add `STRIPE_PRICE_ID` to `.env` for local builds.  
   - In Render, add `STRIPE_PRICE_ID` as a build-time env var (used by `render-build.sh`).

3. **Set Supabase secrets**  
   - You need `SUPABASE_SERVICE_ROLE_KEY` and `STRIPE_SECRET_KEY`.  
   - Use the CLI:
     ```
     supabase secrets set \
       SUPABASE_URL=https://your-project-id.supabase.co \
       SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
       STRIPE_SECRET_KEY=sk_live_...
     ```

4. **Deploy Edge Functions**  
   - From the repo root:
     ```
     supabase functions deploy create-checkout-session
     supabase functions deploy create-portal-session
     ```
   - These live in `supabase/functions/` and are invoked by the app using `supabase.functions.invoke`.

5. **Optional but recommended: subscription status syncing**  
   - The UI reads `profiles.subscription_status` and `profiles.current_period_end`.  
   - If you want this to stay in sync automatically, add Stripe webhooks or the Supabase Payments extension later and update the `profiles` table based on Stripe events.

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
