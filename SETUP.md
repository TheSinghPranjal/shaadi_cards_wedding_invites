# Setup

Manual steps to get Shaadi Cards running. This file grows with each build phase.

## Prerequisites

- Flutter 3.41+ (Dart 3.11+)
- [Supabase CLI](https://supabase.com/docs/guides/cli): `brew install supabase/tap/supabase`
- [Deno 2](https://deno.com) (Edge Functions + DB tests): `brew install deno`

## 1. Supabase project

1. Create a project at <https://supabase.com/dashboard>. Choose the **Mumbai (ap-south-1)** region for Indian users.
2. **Authentication → Sign In / Providers → Allow anonymous sign-ins: ON.**
3. **Authentication → Attack Protection.** Turn on CAPTCHA (Cloudflare Turnstile), or at minimum lower the anonymous sign-up rate limit per IP (for example 30/hour). This stops free-trial farming by reinstalling.
4. Link this repo and push the schema:
   ```sh
   supabase init          # only creates supabase/config.toml; keeps existing migrations
   supabase login
   supabase link --project-ref YOUR-PROJECT-REF
   supabase db push       # applies supabase/migrations/*.sql
   ```
   Or paste `supabase/migrations/20261027120000_init_schema.sql` into **SQL Editor** and run it.
5. Check that **Storage** now has two private buckets, `uploads` and `outputs`, and that **Database → Publications → supabase_realtime** includes `generations` and `profiles`.

## 2. App config

```sh
cp env.example.json env.json   # env.json is git-ignored
```
Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` (Project Settings → API). You can leave the RevenueCat keys empty until Phase 5.

```sh
flutter pub get
dart run build_runner build -d
flutter run --dart-define-from-file=env.json
```

**Check Phase 1:** after the first launch, **Table Editor → profiles** has one row, and **Authentication → Users** shows an anonymous user with the same id.

## Running the checks

```sh
flutter analyze                    # includes riverpod_lint
flutter test
deno test -A supabase/tests        # migrations + credit logic + RLS, on in-memory Postgres
```
