# Plan: Server-verified Share Mission

Created: 2026-07-06 11:30:39

## Objective

Saat ini mission `share_app_daily` memberikan 5 credit begitu tombol "Share" ditekan, tanpa memverifikasi bahwa user benar-benar membagikan aplikasi. Plan ini mengubah mission tersebut menjadi server-verified: reward baru diberikan setelah link yang dibagikan benar-benar diklik (yang hanya bisa terjadi bila user benar-benar menyelesaikan share ke aplikasi lain).

Pendekatan: **nonce + short-link server-verified** lewat custom domain `bikinstiker.com/r/<token>`, dengan App Links (Android) dan Universal Links (iOS) untuk landing kembali ke app.

## Root Cause

- `lib/presentation/screens/missions/missions_screen.dart:218-234` — handler `onComplete` untuk `share_app_daily` memanggil `MissionCompleteRequested` (sama persis dengan mission manual), tidak ada share intent yang dipanggil.
- `supabase/migrations/20260629000022_add_new_missions_and_rules.sql:146-148` — branch `WHEN 'share_app' THEN NULL` di RPC `complete_mission` tidak melakukan validasi apa-apa.
- `lib/core/share_helper.dart` — helper share sudah ada (untuk share stiker) tapi tidak dipakai untuk mission.
- Cooldown 24 jam & daily limit 1 sudah ada (`20260702000013_fix_recurring_mission_limit.sql:171-174`), tapi itu hanya membatasi frekuensi, bukan memverifikasi aksi.

## Scope

- Mission `share_app_daily` saja.
- Native share sheet untuk teks polos (link saja, tanpa stiker) — share stiker dari History/Packs tetap pakai `shareStickerImage` yang sudah ada.
- Hanya authenticated user. Guest user tidak bisa complete mission.
- Tidak mengubah mission lain.

## Out of Scope

- Verifikasi bahwa share benar-benar dipublikasikan ke platform tertentu (Instagram/WhatsApp tidak menyediakan API publik untuk ini).
- Mencegah user membuka link miliknya sendiri (link harus benar-benar diklik di luar app; friction dianggap cukup).
- Migrasi ke `share_plus` v10 (tetap pakai versi yang sudah terpasang).
- Reward tuning (nilai 5 credit tetap).

## High-Level Flow

1. User tap tombol "Share" di tile `share_app_daily`.
2. Client disable tombol, panggil RPC `request_share_token(p_mission_id)`.
3. RPC `request_share_token`:
   - Validasi mission aktif + tier + daily limit + cooldown.
   - Generate `token` (32 byte random, base64url).
   - `expires_at = now() + interval '10 minutes'`.
   - Hapus token lama user untuk mission yang sama (idempotensi).
   - Insert ke `share_tokens` baru.
   - Return `{token, share_url}`.
4. Client panggil `Share.share(text, sharePositionOrigin)` dengan teks berisi ajakan + `https://bikinstiker.com/r/<token>`.
5. Client tampilkan snackbar/dialog: "Tap the link you shared to claim your reward" dengan tombol "Copy link" sebagai fallback.
6. User mengirim share dari share sheet ke WhatsApp/IG/dll. Link tersebar.
7. Suatu saat (bisa di device berbeda) link `https://bikinstiker.com/r/<token>` dibuka.
8. Edge Function `share-redirect` (GET handler):
   - Lookup token; jika tidak ada / expired / sudah consumed → 302 ke store listing dengan param `?share_error=invalid`.
   - Atomic `UPDATE share_tokens SET consumed_at = now(), ip = ..., user_agent = ... WHERE id = $1 AND consumed_at IS NULL AND expires_at > now()`. Jika 0 row affected → 302 ke store dengan `?share_error=consumed`.
   - Panggil RPC `consume_share_token(p_token, p_ip)` di Supabase.
   - RPC `consume_share_token`:
     - Validasi token (not expired, not consumed).
     - Panggil `complete_mission(p_mission_id)` internal (reuse logic existing).
     - Return mission reward summary.
   - Edge Function detect platform via User-Agent:
     - iOS → 302 ke `https://bikinstiker.com/share-claimed/<mission_id>` (Universal Link).
     - Android → 302 ke `https://bikinstiker.com/share-claimed/<mission_id>` (App Link).
     - Desktop/other → 302 ke landing page web `https://bikinstiker.com/share-claimed/<mission_id>` (fallback HTML yang menampilkan "Thanks! Open the app to claim your reward").
9. Saat app dibuka via Universal/App Link:
   - `app_links` plugin menerima URI.
   - `main.dart` (atau navigator key) forward ke `MissionsScreen` dan trigger `MissionLoadRequested` + tampilkan success snackbar.
   - Wallet auto-refresh (sudah ada logic-nya di `missions_screen.dart:82-83`).

## Data Model

### New table: `share_tokens`

```sql
CREATE TABLE public.share_tokens (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  token        TEXT        NOT NULL UNIQUE,
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id   UUID        NOT NULL REFERENCES public.missions(id) ON DELETE CASCADE,
  expires_at   TIMESTAMPTZ NOT NULL,
  consumed_at  TIMESTAMPTZ,
  consumed_ip  TEXT,
  consumed_ua  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX share_tokens_token_idx ON public.share_tokens(token);
CREATE INDEX share_tokens_user_mission_idx ON public.share_tokens(user_id, mission_id);
ALTER TABLE public.share_tokens ENABLE ROW LEVEL SECURITY;
-- user can read their own tokens
CREATE POLICY "user_select_own" ON public.share_tokens
  FOR SELECT TO authenticated USING (user_id = auth.uid());
-- only Edge Function (service role) can update consumed_at
-- no INSERT/UPDATE policy for authenticated -> only via SECURITY DEFINER RPC
```

### New RPC: `request_share_token(p_mission_id UUID)`

- `LANGUAGE plpgsql SECURITY DEFINER`
- Validasi: mission exists & active; user tier mencukupi; daily limit belum tercapai; cooldown terpenuhi (reuse pattern dari `complete_mission`).
- `DELETE FROM share_tokens WHERE user_id = auth.uid() AND mission_id = p_mission_id AND consumed_at IS NULL` (cleanup stale tokens).
- Generate token via `encode(gen_random_bytes(24), 'base64')` → trim `=` → 32 char base64url.
- Insert token dengan `expires_at = now() + interval '10 minutes'`.
- Return: `TABLE(token TEXT, share_url TEXT)` dengan `share_url = 'https://bikinstiker.com/r/' || token`.

### New RPC: `consume_share_token(p_token TEXT, p_ip TEXT, p_ua TEXT)`

- `LANGUAGE plpgsql SECURITY DEFINER`
- Lookup token. Raise `invalid` jika tidak ada / expired / consumed.
- Atomic update `consumed_at = now(), consumed_ip = p_ip, consumed_ua = p_ua WHERE id = ... AND consumed_at IS NULL AND expires_at > now()`.
- Panggil `complete_mission(p_mission_id)` (existing RPC, idempotent terhadap token karena check `v_done_count` dan cooldown tetap berlaku).
- Return `TABLE(mission_id UUID, credits_awarded INT, new_balance INT)`.

### Update `complete_mission` (non-destructive)

Tidak perlu ubah logika. Cooldown & daily limit sudah ada. `consume_share_token` cukup panggil `complete_mission` setelah token consumption sukses.

## Backend: Edge Function `share-redirect`

- Path: `supabase/functions/share-redirect/index.ts`
- Trigger: GET request ke `https://bikinstiker.com/r/<token>`.
- 302 ke:
  - `https://bikinstiker.com/share-claimed/<id>?status=ok` jika Android/iOS.
  - `https://bikinstiker.com/share-claimed/<id>?status=ok` (HTML landing) untuk platform lain.
  - Store listing dengan `?share_error=...` jika token invalid.
- Implementation outline (pseudo):
  ```ts
  const token = params.pathname.split('/').pop();
  const ua = req.headers.get('user-agent') || '';
  const ip = req.headers.get('x-forwarded-for') || '';
  const { data, error } = await supabase.rpc('consume_share_token', { p_token: token, p_ip: ip, p_ua: ua });
  // pick redirect URL based on ua + data
  return new Response(null, { status: 302, headers: { Location: redirectUrl } });
  ```
- Konfigurasi di `supabase/config.toml`: function name `share-redirect`, `verify_jwt = false` (public endpoint), `no_verify_jwt = true` (anonymous allowed).

## Native Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)

Tambah 2 intent-filter ke `MainActivity`:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="bikinstiker.com" android:pathPrefix="/share-claimed/"/>
</intent-filter>
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="bikinstiker"/>
</intent-filter>
```

Host `https://bikinstiker.com/.well-known/assetlinks.json` (tidak di repo ini, di-hosting terpisah). Fingerprint SHA-256 harus cocok dengan signing key release & debug.

### iOS (`ios/Runner/Runner.entitlements` baru)

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:bikinstiker.com</string>
</array>
```

Tambah file ke Xcode target `Runner`. Update `Info.plist` untuk custom URL scheme `bikinstiker` (jika belum ada):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>bikinstiker</string></array>
  </dict>
</array>
```

Host `https://bikinstiker.com/.well-known/apple-app-site-association` (di server statis, di luar repo).

## Flutter Changes

### `lib/core/services/share_mission_service.dart` (NEW)

```dart
class ShareMissionService {
  Future<ShareToken> requestToken({required String missionId}); // calls RPC
  Future<ShareResult> openShareSheet({required String text});   // calls Share.share
  Stream<Uri> get deepLinkStream;                                // app_links stream
}
```

### `lib/data/repositories/mission_repository.dart`

- Tambah `requestShareToken(String missionId) → ShareTokenInfo`.
- `ShareTokenInfo { token, shareUrl, expiresAt }`.

### `lib/presentation/blocs/mission/mission_bloc.dart`

- Event baru `MissionShareRequested(userId, missionId)`.
- Handler:
  1. Set `pendingMissionIds += {missionId}` (lock button).
  2. Panggil `_repo.requestShareToken(missionId)` → dapat `shareUrl`.
  3. Panggil `Share.share(_buildShareText(shareUrl), sharePositionOrigin)`.
  4. Emit state dengan `shareDialogOpen = true` (field baru) agar UI bisa menampilkan instruksi "Open the link you shared to claim".
  5. Listen ke `ShareMissionService.deepLinkStream`; saat URI match `bikinstiker://share-claimed?mission=<id>`, panggil `_repo.completeMission(userId, missionId)` (existing flow, akan insert progress + credit) dan emit `successMessage`.
- State baru: `sharePromptMissionId: String?` (untuk UI menampilkan dialog "Open the link to claim").

### `lib/presentation/screens/missions/missions_screen.dart`

- Ubah handler `onComplete` di `_MissionTile`:
  ```dart
  if (mission.code == 'share_app_daily') {
    context.read<MissionBloc>().add(MissionShareRequested(userId, mission.id));
  } else if (mission.code == 'watch_video_ad') {
    // existing
  } else {
    // existing
  }
  ```
- Tambah `BlocListener` untuk `sharePromptMissionId`: tampilkan dialog/snackbar informatif.
- Tambah listener untuk deep link yang sudah di-handle di BLoC (no extra UI logic needed di screen).

### `lib/main.dart`

- Init `ShareMissionService` di `setupDependencies()`.
- Di `MaterialApp.builder` atau global navigator: subscribe ke `ShareMissionService.deepLinkStream`; saat URI masuk, push event `MissionShareDeepLinkReceived(missionId)` ke `MissionBloc` jika `state.sharePromptMissionId` cocok.

## Edge Cases & Failure Modes

- **Network failure saat request token**: tampilkan snackbar "Failed to prepare share. Please try again.", unlock button.
- **Network failure saat share sheet**: tetap tampilkan token URL di snackbar agar user bisa copy manual.
- **Link dibuka di device yang tidak punya app**: redirect ke landing page HTML "Thanks for sharing! Open the BikinStiker app to claim 5 credits." dengan link ke store.
- **Token dibuka 2x**: atomic `consumed_at IS NULL` guard memastikan hanya 1 consume sukses. Yang ke-2 dapat `?share_error=consumed` di store page.
- **Token expired (10 menit)**: `?share_error=expired`.
- **Cooldown/daily limit terpenuhi saat consume**: `complete_mission` akan raise exception → Edge Function respond 302 dengan `?share_error=cooldown`. Tidak ada double reward.
- **User uninstall app setelah share tapi sebelum open link**: token masih valid server-side. Jika user reinstall & buka link di device yg sama (mis. dari history browser), App Link akan trigger consume. Cold start, `app_links` membaca initial link, push ke `MissionBloc`.
- **iOS Safari strip Universal Link param**: di-handle dengan menyimpan state di `MissionState.sharePromptMissionId`; saat deep link masuk tanpa match, anggap klaim sudah selesai (server sudah record).
- **Race: user tap Share 2x**: `pendingMissionIds` lock button + `request_share_token` DELETE stale tokens → request kedua dapat token baru, share sheet terbuka 2x. Bisa di-improve dengan `shareDialogOpen` state lock.

## Tasks

- [ ] Tulis migration `supabase/migrations/20260706000001_share_tokens_and_rpcs.sql` (table + 2 RPCs + RLS).
- [ ] Tulis Edge Function `supabase/functions/share-redirect/index.ts` + entry di `config.toml`.
- [ ] Update `lib/data/repositories/mission_repository.dart`: tambah `requestShareToken`.
- [ ] Buat `lib/core/services/share_mission_service.dart` (RPC wrapper + share_plus + app_links stream).
- [ ] Register service di `lib/core/di.dart`.
- [ ] Tambah event `MissionShareRequested` + handler di `mission_bloc.dart`; tambah field `sharePromptMissionId` di state.
- [ ] Update `missions_screen.dart`: route `share_app_daily` ke handler baru + tampilkan prompt dialog.
- [ ] Update `lib/main.dart`: inisialisasi `app_links` stream, listen ke deep link, push ke bloc.
- [ ] Tambah intent-filter di `AndroidManifest.xml` (App Link + custom scheme).
- [ ] Tambah `Runner.entitlements` di iOS + `Info.plist` custom scheme.
- [ ] Host `assetlinks.json` & `apple-app-site-association` di `bikinstiker.com/.well-known/`.
- [ ] Buat landing page statis `https://bikinstiker.com/share-claimed/<id>` (HTML minimal).
- [ ] Update mission description di DB: `description = 'Share BikinStiker and open the link to earn 5 credits'`.
- [ ] Update `PROJECT_MEMORY.md` setelah selesai.

## Risks

- **App Link / Universal Link setup** butuh akses ke domain `bikinstiker.com` + signing key fingerprint. Jika belum siap, seluruh flow tidak akan berfungsi di production. Mitigasi: gunakan `bikinstiker://` custom scheme sebagai fallback (manual user copy + paste).
- **iOS paste**: custom scheme di-share text kadang di-strip atau di-trim oleh aplikasi chat. Mitigasi: tampilkan token URL eksplisit di snackbar setelah share, supaya user bisa copy manual.
- **Edge Function cold start** Supabase Functions menambah latency ~500ms pada first request. Untuk share claim ini tidak masalah (user tidak menunggu).
- **RLS pada `share_tokens`**: pastikan service-role Edge Function dapat update `consumed_at` (pakai service role key di function).
- **Anti-bot bypass**: user yang berbeda device untuk share dan click link tidak bisa kami deteksi. Rate limit di Edge Function berdasarkan IP masih bisa di-bypass via VPN. Pertimbangkan tambahan device fingerprint hash (opsional, v2).

## Validation Steps (User-side)

- `supabase db push` (apply migration).
- `supabase functions deploy share-redirect`.
- Tambah `applinks:bikinstiker.com` di iOS entitlements (Xcode).
- Host `assetlinks.json` & `apple-app-site-association` di `bikinstiker.com/.well-known/`.
- (Optional) `flutter run` di device Android + iOS.
- Test cases:
  1. Tap Share → share sheet muncul dengan URL `https://bikinstiker.com/r/xxx` → dismiss tanpa kirim → tidak ada reward.
  2. Tap Share → kirim ke WhatsApp → buka chat → tap link di WhatsApp → app terbuka ke Missions → success snackbar + 5 credit.
  3. Tap Share → buka link di device yg sama (browser) → app cold start via Universal/App Link → success.
  4. Buka link 2x → hanya 1 reward (cek `user_mission_progress` dan `credit_transactions`).
  5. Tunggu >10 menit → buka link → `?share_error=expired`, tidak ada reward.
  6. Tap Share 2x dalam 1 hari → yang ke-2 raise "Daily mission limit reached" (sudah ada di `complete_mission`).

## Commit Message Proposal

```
feat(missions): verify share_app_daily via single-use short link
```

## Open Questions (minor, default sudah dipilih)

- **Reward value**: keep 5 credits (default).
- **Token TTL**: 10 minutes (default; bisa diubah ke 30 min jika dirasa terlalu ketat).
- **Landing page web**: HTML statis di `bikinstiker.com/share-claimed/<id>` minimal. Bisa ditambahkan kemudian.
- **Custom URL scheme `bikinstiker://` vs Universal Link only**: tetap dual (custom scheme sebagai fallback robustness).
