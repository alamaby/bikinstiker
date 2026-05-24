# BikinStiker

AI-powered WhatsApp sticker generator. Users pick a preset style + type a short prompt → the backend builds a strict "die-cut sticker, pure white background" prompt → calls the OpenRouter `sourceful/riverflow-v2-fast` model → atomically deducts credits and returns a freshly generated sticker.

---

## Table of Contents
1. [Architecture](#architecture)
2. [Tech stack](#tech-stack)
3. [Repository layout](#repository-layout)
4. [Prerequisites](#prerequisites)
5. [Local setup](#local-setup)
6. [Database migrations](#database-migrations)
7. [Edge function deployment](#edge-function-deployment)
8. [Running the Flutter app](#running-the-flutter-app)
9. [State management approach](#state-management-approach)
10. [Security model](#security-model)
11. [Accessibility (Okabe-Ito palette)](#accessibility-okabe-ito-palette)
12. [Verification checklist](#verification-checklist)
13. [Troubleshooting](#troubleshooting)

---

## Architecture

```
┌─────────────────────────┐         ┌────────────────────────────────────┐
│      Flutter app        │         │          Supabase backend          │
│                         │         │                                    │
│  UI (Material 3)        │         │  Auth (email + password)           │
│   ↓                     │         │  Postgres                          │
│  BLoCs (flutter_bloc)   │  HTTPS  │   ├─ user_wallets                  │
│   ↓                     │ ◀────── │   ├─ credit_transactions (ledger)  │
│  Repositories           │         │   ├─ sticker_generations           │
│   ↓                     │         │   └─ RPC deduct_credit_for_sticker │
│  SupabaseClient         │         │  Storage (private 'stickers')      │
│                         │         │  Edge function: generate-sticker ──┼─▶ OpenRouter
└─────────────────────────┘         └────────────────────────────────────┘
```

The client never speaks to OpenRouter directly. Every generation flows through the `generate-sticker` edge function, which owns the OpenRouter API key, drives the atomic credit deduction RPC, performs the upload, and returns a short-lived signed URL.

Clean-architecture layering inside `bikin_stiker/lib`:

| Layer | Folder | Purpose |
|---|---|---|
| Presentation | `presentation/screens`, `presentation/widgets` | Pure UI, reads BLoC state |
| State | `presentation/blocs` | `flutter_bloc` — Auth, Wallet, StickerGen, History |
| Domain glue | `data/repositories` | Interface + Supabase implementation |
| Data sources | `data/datasources`, `data/models` | Supabase client bootstrap, DTOs |
| Cross-cutting | `core/` | Theme, presets, DI, error types |

Dependencies always point downward; UI never imports `supabase_flutter` directly.

---

## Tech stack

- **Frontend**: Flutter 3.41 (Dart 3.11), `flutter_bloc`, `equatable`, `get_it`, `flutter_dotenv`, `cached_network_image`, `intl`.
- **Backend**: Supabase (Auth + Postgres + Storage + Edge Functions).
- **Edge runtime**: Deno + TypeScript.
- **AI provider**: OpenRouter, model `sourceful/riverflow-v2-fast` with `modalities: ["image"]`.

---

## Repository layout

```
.
├── bikin_stiker/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── theme/app_theme.dart
│   │   │   ├── constants/presets.dart
│   │   │   ├── errors/failures.dart
│   │   │   └── di.dart
│   │   ├── data/
│   │   │   ├── datasources/supabase_client.dart
│   │   │   ├── models/{wallet,sticker_generation,credit_transaction}.dart
│   │   │   └── repositories/{auth,wallet,sticker}_repository.dart
│   │   └── presentation/
│   │       ├── blocs/{auth,wallet,sticker_gen,history}/
│   │       ├── screens/{auth,home,history}/
│   │       └── widgets/status_indicator.dart
│   ├── pubspec.yaml
│   ├── .env.example
│   └── test/widget_test.dart
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 20260505000001_init_schema.sql
│   │   ├── 20260505000002_wallet_trigger.sql
│   │   └── 20260505000003_storage_bucket.sql
│   └── functions/
│       └── generate-sticker/
│           ├── index.ts
│           └── deno.json
├── README.md
└── LICENSE
```

---

## Prerequisites

- Flutter SDK ≥ 3.41 (Dart ≥ 3.11)
- Supabase CLI ≥ 1.200 (`scoop install supabase` or `brew install supabase/tap/supabase`)
- Docker Desktop (for local Supabase stack)
- Deno (only required if you want to run the edge function locally without Supabase CLI)
- OpenRouter API key with access to `sourceful/riverflow-v2-fast`

---

## Local setup

```bash
# 1. Clone & install Flutter deps
cd bikin_stiker
cp .env.example .env       # fill in SUPABASE_URL + SUPABASE_ANON_KEY
flutter pub get

# 2. Start Supabase locally (from repo root)
cd ..
supabase start             # spins up Postgres, Auth, Storage, Studio
```

After `supabase start` completes, copy the printed `API URL` and `anon key` into `bikin_stiker/.env`.

---

## Database migrations

All schema, RLS policies and RPCs live in `supabase/migrations/` as raw SQL — the source of truth.

```bash
# Local: re-apply all migrations from a clean state
supabase db reset

# Remote: push migrations to your linked project
supabase link --project-ref <YOUR-PROJECT-REF>
supabase db push
```

Migrations included:

| File | What it does |
|---|---|
| `20260505000001_init_schema.sql` | Tables (`user_wallets`, `credit_transactions`, `sticker_generations`), `transaction_type` enum, indexes, RLS (SELECT-only for owners), and the SECURITY DEFINER RPCs `deduct_credit_for_sticker` and `refund_failed_sticker`. |
| `20260505000002_wallet_trigger.sql` | `on_auth_user_created` trigger → auto-creates a `user_wallets` row with **5 starter credits** + a matching `topup` ledger entry on every signup. |
| `20260505000003_storage_bucket.sql` | Creates a **private** `stickers` bucket. RLS lets users `SELECT` only objects under `stickers/{auth.uid()}/...`. Uploads happen exclusively from the edge function via the service role. |

Mutations against `user_wallets`, `credit_transactions`, and `sticker_generations` are intentionally not exposed via RLS policies — every state change must go through the SECURITY DEFINER RPCs (called from the edge function) so the ledger remains the immutable source of truth.

---

## Edge function deployment

The function `supabase/functions/generate-sticker/index.ts` does the following on every call:

1. Authenticates the JWT and resolves `auth.uid()`.
2. Validates `{ userInput, presetId }`, caps prompt length at 200 chars, rejects unknown presets.
3. Maps the preset to a concrete style descriptor and builds the strict final prompt:
   `die-cut sticker, pure white background, thick white border, centered subject, no shadow, high contrast, <style> style. Subject: <userInput>`.
4. Calls `deduct_credit_for_sticker(p_user_id, p_cost=1, p_preset, p_prompt)`. If insufficient → HTTP 402.
5. Calls OpenRouter `sourceful/riverflow-v2-fast` with `modalities: ["image"]`.
6. Uploads the resulting bytes to `stickers/{user_id}/{sticker_id}.png` using the **service role** key.
7. Updates the row with `image_url`, `final_prompt`, and `status='success'`.
8. Returns `{ stickerId, signedUrl, path, finalPrompt }` (signed URL valid 1 hour).
9. On any failure after step 4, calls `refund_failed_sticker` to mark the row failed, restore the balance, and write a compensating `refund` ledger row.

### Set secrets

```bash
supabase secrets set OPENROUTER_API_KEY=sk-or-...
# SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY are auto-injected.
```

### Deploy

```bash
supabase functions deploy generate-sticker
```

### Run locally

```bash
supabase functions serve generate-sticker --env-file .env.local
```

Then `curl -X POST http://localhost:54321/functions/v1/generate-sticker \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"presetId":"kawaii","userInput":"a smiling boba tea cup"}'`

---

## Running the Flutter app

```bash
cd bikin_stiker
flutter pub get
flutter run        # picks up the connected device / emulator
```

Static analysis & tests:
```bash
flutter analyze    # currently clean
flutter test
```

---

## State management approach

The app uses **`flutter_bloc`**. Why BLoC:

- Strict `Event → State` flow makes async side-effects (auth, generation) auditable.
- Stream-based states pair naturally with Supabase realtime (`WalletBloc` watches the wallet stream).
- Easy to test with `bloc_test` + `mocktail`.

Layers:

```
View (Screen)
  ↳ context.read<Bloc>().add(Event)
        ↳ Bloc.handler — calls Repository
              ↳ Repository — wraps SupabaseClient / Edge Function
                    ↳ DataSource (SupabaseClient)
emit(State)  ←  Bloc receives result
```

Four blocs:

| Bloc | Responsibility |
|---|---|
| `AuthBloc` | Subscribes to `auth.onAuthStateChange`. Drives `unauthenticated / authenticated / submitting`. |
| `WalletBloc` | Subscribes to a Supabase realtime stream on `user_wallets` filtered by `user_id`. Emits the live balance. |
| `StickerGenBloc` | Single-shot `idle → submitting → success(signedUrl) | failure(Failure)` for each generation. |
| `HistoryBloc` | Loads paginated history via repository on demand. |

Dependency injection uses `get_it` and is wired up in `core/di.dart`. Repositories are exposed to the widget tree via `MultiRepositoryProvider` so they can be overridden in tests.

---

## Security model

- **OpenRouter API key never leaves the server.** Stored as a Supabase Functions secret; only the edge function can read it.
- **Atomic credit deduction.** `deduct_credit_for_sticker` is a SECURITY DEFINER PL/pgSQL function that takes `FOR UPDATE` lock on the wallet row, checks balance, decrements, inserts the sticker row, and writes the matching ledger entry — all in one transaction.
- **Immutable ledger.** No client (or even authenticated user via SQL) can `INSERT/UPDATE/DELETE` directly. Every credit movement is an append-only row in `credit_transactions`.
- **RLS everywhere.** All three tables enable RLS with SELECT-only owner policies. No public columns, no `auth.role() = 'service_role'` exemptions visible to the client.
- **Private storage + signed URLs.** The `stickers` bucket is private. Owners can only `SELECT` objects whose first path segment matches their `auth.uid()`. Uploads happen exclusively from the edge function with the service role key.
- **Refund on failure.** Any post-RPC error (OpenRouter outage, upload failure, etc.) triggers `refund_failed_sticker`, which guards against double-refund via a status check.
- **Validation at the edge.** Prompt length cap (200 chars) and preset whitelist enforced server-side; clients can't smuggle arbitrary style strings.

---

## Accessibility (Okabe-Ito palette)

The UI uses the **Okabe-Ito color-blind-safe palette** to remain legible under the 8 most common forms of color vision deficiency.

| Role | Color | Hex |
|---|---|---|
| Primary | Blue | `#0072B2` |
| Secondary / CTA | Orange | `#E69F00` |
| Error | Vermilion | `#D55E00` |
| Success | Bluish Green | `#009E73` |
| Background | White | `#FFFFFF` |
| Text on background | Near-black | `#111111` |

**Crucially, color is never the sole signaling channel.** Every status, button, and chip pairs:
- An icon (`Icons.check_circle`, `Icons.error_outline`, `Icons.bolt`, …)
- A text label (`Done`, `Failed`, `Low credits`)
- The semantic Okabe-Ito color

See `lib/presentation/widgets/status_indicator.dart` for the canonical pattern.

---

## Verification checklist

The following checks are documented for manual validation — they are **not** wired into CI for you yet.

1. **DB migrations:** `supabase db reset` runs cleanly. Inserting a fake user into `auth.users` should auto-create a `user_wallets` row with balance=5 via the trigger. Calling `deduct_credit_for_sticker` with insufficient balance should raise; with balance, should produce a `pending` sticker_generations row + a negative `credit_transactions` row, all in one transaction.
2. **Edge function (local):** `supabase functions serve generate-sticker --env-file .env.local`, then `curl` POST with a valid JWT and `{userInput, presetId}` should return 200 with `{stickerId, signedUrl, path}`. The image should land in Storage at `stickers/{uid}/{id}.png` and the row should flip to `status='success'`.
3. **Failure path:** With an invalid `OPENROUTER_API_KEY`, the function should return 5xx, the row should flip to `status='failed'`, the wallet balance should be restored, and a `refund` `credit_transactions` row should appear.
4. **Flutter end-to-end:** `flutter run` → sign up → starter credits visible → generate sticker → image renders → balance decrements → history shows the entry. Sign in as a second user to confirm RLS isolates data.
5. **Accessibility:** Toggle Android Deuteranopia simulation under Developer options; all status indicators should remain distinguishable thanks to the icon + text pairing. `flutter analyze` should report `No issues found!`.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `StateError: Missing SUPABASE_URL` on startup | `bikin_stiker/.env` is missing or not listed under `flutter.assets` in `pubspec.yaml`. |
| `Insufficient credits` on first generation | Wallet trigger didn't fire. Confirm migration `20260505000002_wallet_trigger.sql` was applied (`select * from public.user_wallets where user_id = '<uid>'`). |
| Sticker row stuck in `pending` | Edge function crashed mid-execution. Check `supabase functions logs generate-sticker`. The `refund_failed_sticker` RPC is idempotent — call it manually if needed. |
| `403` when fetching signed URL | The bucket policy in migration 3 didn't apply, or the storage path doesn't start with the user's `auth.uid()`. |
| Wallet balance doesn't update live | Realtime is disabled for the `user_wallets` table on your remote project. Enable replication in Supabase Studio → Database → Replication. |

---

## License

See [LICENSE](LICENSE).
