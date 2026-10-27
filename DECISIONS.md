# Decisions & assumptions

Running log of choices made where the brief was ambiguous or a constraint forced a change.

## Placeholders from the brief

| Placeholder | Value used | Notes |
|---|---|---|
| `{{APP_NAME}}` | **Shaadi Cards** | Taken from the project folder. Lives in `Env.appName`, the Android label and the iOS display name. |
| `{{AI_PROVIDER}}` | **Google Gemini image model** | The brief's default. Implemented behind `ImageGenProvider` in Phase 3. |
| `{{PRICE_5/15/40}}` | Set in Play Console / App Store Connect | The app never hard-codes prices; it shows RevenueCat offering prices. |

## Phase 1 — Foundation

- **Riverpod 3.1 instead of the newest 3.3.** This machine has Flutter 3.41.6 / Dart 3.11. `riverpod_lint` ≥ 3.1.6 and `riverpod_annotation` ≥ 4.0.5 need Dart 3.12, so pub settled on `flutter_riverpod 3.1.0`, `riverpod_annotation 4.0.0`, `riverpod_generator 4.0.0+1`, `riverpod_lint 3.1.0`. After upgrading Flutter, bump them all together.
- **No `custom_lint`.** `riverpod_lint` 3.x is an `analysis_server_plugin`, enabled in `analysis_options.yaml` and run by `flutter analyze` / `dart analyze`. `dart run custom_lint` would find no rules to run, so CI runs `flutter analyze` instead. Verified: a deliberate violation shows `riverpod_syntax_error` in `flutter analyze`.
- **No `permission_handler`.** `permission_handler_android` 14.1 only builds with AGP 9, and the project is on AGP 8.11. It also isn't needed: `gal` requests its own gallery permission (`Gal.requestAccess`), and `image_picker` uses the Android Photo Picker, which needs no permission. The brief says "only where truly required".
- **Riverpod automatic retry is turned off** (`ProviderScope(retry: (_, _) => null)`). The UI has explicit retry buttons, and a provider that creates a paid generation must never re-send silently.
- **`publishableKey` instead of `anonKey`** in `Supabase.initialize`. `anonKey` is deprecated in supabase_flutter 2.18. The env var is still called `SUPABASE_ANON_KEY`; either the legacy anon key or the new publishable key works.
- **The app runs without Supabase keys.** If `env.json` is missing, the splash shows a friendly error with "Continue offline", and the card maker still works.
- **Text scale is capped at 1.3×** app-wide (the brief's accessibility requirement), so layouts don't break.
- **Android `minSdk` is 24**, and `INTERNET` is declared in the main manifest. Flutter's template only adds it to debug builds, so release builds would otherwise fail every network call.
- **Fonts** are static TTFs from Google Fonts (all OFL), bundled under `assets/fonts/`: Playfair Display (headings), Poppins (UI), Great Vibes / Alex Brush / Dancing Script (script names), Cinzel / Cormorant Garamond (formal), Noto Sans Devanagari / Tiro Devanagari Hindi / Yatra One (Hindi). Noto Sans Devanagari is the `fontFamilyFallback` on every app text style, so Hindi always renders.

## Database

- **`profiles.free_credits` added.** The brief has one `credits` column but also needs to know whether a free or paid credit was spent (for watermarking). `credits` stays the total balance; `free_credits` is how many of those are free. A check constraint keeps `0 ≤ free_credits ≤ credits`.
- **`spend_credit(user_id, ref, reason, mode)`** with `mode` = `free_first` (default) | `paid_first` | `paid_only`. `unlock-hd` uses `paid_only`, so a free credit can't remove a watermark. It returns `was_free`, which becomes `generations.is_watermarked`.
- **`refund_credit(user_id, ref, reason)`** is a separate idempotent function. It restores the same kind of credit that was spent. Refund ledger rows use `ref = '<reason>:<generation_id>'` so they don't collide with `unique (reason, ref)`.
- **`grant_credits`** also sets `has_purchased` (for a purchase) and `free_credits_granted` (for a free trial) in the same transaction.
- **`credit_ledger.is_free`** was added for auditing and refunds.
- **No `original_paths` column.** Unwatermarked originals for free results sit at a fixed path, `outputs/{user}/{gen}/original/{i}.png`, and a storage policy hides that folder from the owner. A column-level `REVOKE` doesn't work while Supabase grants table-level `SELECT`, and the DB tests caught that.
- **Credit functions are executable only by `service_role`.** `EXECUTE` is revoked from `public`, `anon` and `authenticated`, because Supabase grants it to them by default. Tests check this.
- **`generations.updated_at`** was added, with a trigger, for debugging stuck jobs.
- **DB tests run on PGlite** (Postgres in WASM) through Deno, with small stand-ins for Supabase's `auth` / `storage` schemas, so they need no Docker. They complement testing against a real Supabase local stack; they don't replace it.
