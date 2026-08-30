# Plan: Profile + My Sticker Packs + Daily Check-in Polish

Created: 2026-07-04 09:57:32

## Objective

Tutup 6 bug report user dari layar Profile, My Sticker Packs, Pack Detail, dan Daily Check-in:

1. Credit History filter "Earnings" tidak menampilkan data, label chip ambigu.
2. Subscription section tidak menampilkan kapan free credit bulanan diberikan.
3. PackCard thumbnail masih generic icon (harus pakai stiker pertama).
4. PackCard layout: nama pack terlalu ke kiri & terlalu ke bawah.
5. PackDetailScreen image belum ambil dari cache lokal (WebP di appSupportDir).
6. Daily Check-in tidak ada animasi Lottie saat claim berhasil.

## Scope (berdasarkan jawaban user)

- **Earnings filter** = semua income (amount > 0): daily_reward, mission_reward, subscription_grant, topup, admin_grant, refund.
- **Free credit timing** = tampil untuk Free & Plus; fallback hitung dari `subscription.startedAt + N×30 hari` jika `last_grant_at` belum tersedia.
- **PackCard thumbnail** = first sticker signed URL (dengan fallback tray icon → generic icon).
- **PackCard padding** = tambah padding internal saja (horizontal: 14, vertical: 14 + SizedBox 4 sebelum nama).
- **PackDetail image cache** = cek file lokal dulu di `pack_stickers/{packIdentifier}/{stickerId}.webp`, fallback ke `Image.network` signedUrl.
- **Daily checkin lottie** = celebration overlay + bounce pada day box yang baru di-claim.

## Milestones

1. Refactor credit history filter chip + repository filter.
2. Tampilkan info "next grant" di Subscription section.
3. PackCard: thumbnail first sticker + padding fix.
4. PackDetailScreen: prefer local WebP cache.
5. Daily Check-in: Lottie overlay + day box bounce.
6. Update PROJECT_MEMORY.md.

## Tasks

### 1. Credit History filter

- [ ] `lib/data/repositories/credit_transaction_repository.dart`
  - Ubah signature `fetchTransactions` agar menerima multi-type via `Set<CreditTxType>?` (rename param atau tambahkan `types: Set<CreditTxType>?`).
  - Saat `types` non-null dan > 1, gunakan `.in_('type', [snake_case_values])` dari `_txTypeToDb`.
  - Saat `types` null atau kosong, tetap tanpa filter type (All).
- [ ] `lib/presentation/blocs/credit_transactions/credit_transactions_bloc.dart`
  - Tambah `types` field di state; copyWith support.
  - `_fetch` baca `state.types` dan teruskan ke repo.
  - Tambahkan helper enum `CreditTxCategory { all, income, spent, rewards }` atau cukup gunakan set langsung di UI.
- [ ] `lib/presentation/screens/profile/profile_screen.dart`
  - Ganti chip set:
    - **All** → `types: null`
    - **Earnings** → semua type dengan `amount > 0` saat fetch → repo butuh opsi `positiveAmount: bool`. Alternatif lebih bersih: kirim `types: {topup, dailyReward, missionReward, subscriptionGrant, adminGrant, refund}` dan biarkan UI filter.
  - Pertahankan "Spent" = `{generateSticker}`, "Rewards" = `{dailyReward, missionReward}`.
- [ ] Verifikasi: pilih Earnings → muncul semua row income.

### 2. Subscription free-credit next grant

- [ ] Tambah RPC SQL kecil `get_next_grant_info(p_user_id uuid)` di `supabase/migrations/20260704000001_subscription_next_grant.sql`:
  - Input: user_id.
  - Output: `(tier text, last_grant_at timestamptz, next_grant_at timestamptz, days_until_next int, monthly_amount int)`.
  - Logika: baca `user_wallets.last_grant_at` (jika NULL → `subscription.startedAt`), hitung `next_grant_at = date_trunc('month', last_grant_at) + interval '1 month'`. `monthly_amount`: 5 untuk free, configurable untuk plus (cek RPC `grant_monthly_credits`).
  - SECURITY DEFINER + auth.uid() check.
- [ ] `lib/data/models/subscription_next_grant.dart` (baru): fields di atas.
- [ ] `lib/data/repositories/subscription_repository.dart`
  - Tambah `Future<SubscriptionNextGrant?> fetchNextGrant(String userId)`.
- [ ] `lib/presentation/blocs/subscription/subscription_bloc.dart`
  - Tambah event `SubscriptionNextGrantRequested`, simpan `nextGrant` di state.
  - Dispatch otomatis setelah `_onStart` dan `_onUpdated`.
- [ ] `lib/presentation/screens/profile/profile_screen.dart` — `_buildEntitlementsSection`
  - Tambah baris info:
    - Free: "Next free credits (+5) in N days on {date}".
    - Plus: "Next Plus credits in N days on {date}".
    - Cycle complete: tampilkan "Cycle complete, next grant on {date}".

### 3. PackCard thumbnail first sticker

- [ ] `lib/data/repositories/sticker_pack_repository.dart`
  - Modifikasi `fetchUserPacks` RPC: extend dengan `first_sticker_path` (kolom baru atau cukup dari `get_user_packs` view) → `createSignedUrl(first_sticker_path)`. Bisa juga lewat RPC baru atau join. **Pertanyaan**: apakah `get_user_packs` sudah ada akses ke items? Cek SQL → kalau tidak, tambahkan migration `20260704000002_user_packs_first_sticker.sql` yang modify RPC untuk join `sticker_pack_items` order by position limit 1.
  - Sederhanakan: tambah method `getPackFirstStickerSignedUrl(packId)` di repo yang panggil RPC `get_pack_detail` lalu ambil `items.first.stickerSignedUrl`.
- [ ] `lib/data/models/sticker_pack.dart`
  - Tambah field `String? firstStickerSignedUrl`.
  - Update `fromJson` (opsional: lewat parameter named `firstStickerSignedUrl` agar tidak breaking).
- [ ] `lib/presentation/blocs/sticker_pack/sticker_pack_bloc.dart`
  - `_onLoad`: setelah `fetchUserPacks`, panggil `signedUrlForFirstSticker` untuk setiap pack (paralel via `Future.wait`), populate field baru.
- [ ] `lib/presentation/widgets/pack_card.dart`
  - Ganti placeholder generic: jika `pack.firstStickerSignedUrl != null` → `Image.network` dengan `errorBuilder` ke tray icon / generic. Tetap `ClipRRect`.

### 4. PackCard padding

- [ ] `lib/presentation/widgets/pack_card.dart`:
  - Padding bawah dari `EdgeInsets.all(12)` → `EdgeInsets.fromLTRB(14, 12, 14, 14)`.
  - Tambah `const SizedBox(height: 4)` sebelum `Text(pack.name, ...)`.
  - `Expanded` → biarkan (sudah center).

### 5. PackDetailScreen prefer local WebP cache

- [ ] `lib/presentation/screens/packs/pack_detail_screen.dart` — `_StickerItemTile`
  - Fungsi `_localWebpPath(item)` → `Path = '{appSupportDir}/pack_stickers/{pack.packIdentifier}/{item.stickerGenerationId}.webp'`. Cek dengan `File(path).exists()` via async pattern.
  - Karena tile build synchronous, dua opsi:
    - (a) Convert `_StickerItemTile` ke StatefulWidget + `initState` cek file existence → simpan bool lokal. Tidak pre-fetch gambar (akan di-load saat render).
    - (b) Pakai `FutureBuilder<File>` di leading.
  - Pilih **(a)** agar minimal invasif. Render `Image.file(localPath)` jika ada else `Image.network(signedUrl)`.
- [ ] Tambah dependency path_provider (sudah ada) — tidak perlu import baru.

### 6. Daily checkin lottie

- [ ] `lib/presentation/widgets/lottie_overlay.dart` (baru): StatefulWidget reusable:
  - Props: `String asset`, `Duration autoDismiss = const Duration(milliseconds: 1500)`, `VoidCallback? onDismiss`.
  - Render `Lottie.asset` centered full-screen dengan `IgnorePointer`. Pakai `AnimatedOpacity` untuk fade in/out.
  - Fallback ke `SizedBox.shrink` jika asset missing atau `MediaQuery.disableAnimationsOf(context)`.
- [ ] `lib/presentation/screens/missions/widgets/daily_checkin_card.dart`
  - Tambah field `int? justClaimedDay` (dikontrol parent).
  - `_DayBox` tambah prop `bool highlightBounce`. Gunakan `AnimatedScale` (scale: 1.0 → 1.25 → 1.0) selama 600ms saat `highlightBounce == true`. Trigger via `TickerProviderStateMixin`.
- [ ] `lib/presentation/blocs/mission/mission_bloc.dart`
  - Tambah state field `int? lastClaimedDay` di `MissionState` (opsional, atau pakai event sukses + parsed value).
  - State copyWith support.
- [ ] `lib/presentation/screens/missions/missions_screen.dart`
  - Listener `BlocListener<MissionBloc>` untuk `checkin_success:N` → set `_showLottieOverlay = true` lalu auto-hide. Set `lastClaimedDay = N` dan kirim ke `DailyCheckinCard`.
  - Render `LottieOverlay` di Stack root body.

## Risks & Mitigations

| # | Risk | Mitigation |
|---|---|---|
| R1 | Filter multi-type bisa kirim array kosong jika user pilih earnings lalu server reject | Repo cek empty `types` → treat as null (no filter) |
| R2 | RPC `get_next_grant_info` baru butuh re-deploy + db push | Tambah migration; deployed bersama Flutter change |
| R3 | `firstStickerSignedUrl` membuat `fetchUserPacks` lambat (parallel signed URL calls) | Limit ke pack yang visible di list (max 30), signed URL di-cache oleh `signedUrlForPath` existing |
| R4 | `Image.file` di Android butuh permission yang berbeda dari `Image.network` | `getApplicationSupportDirectory()` sudah app-private, tidak butuh permission |
| R5 | Lottie overlay blocking tap | Pakai `IgnorePointer` + `barrierDismissible: true` |
| R6 | Day box bounce setiap rebuild → animasi berulang | Pakai `TickerProvider` dan trigger hanya pada `widget.justClaimedDay` change |

## Validation

```bash
# Build & static analysis
dart format lib/
flutter analyze
flutter test

# Migrations (deploy order)
cd supabase && git pull origin main
supabase db push
supabase functions deploy generate-sticker  # if needed

# Smoke checklist (manual di device):
# 1. Profile → Credit History → tap Earnings → muncul baris income
# 2. Profile → Subscription → baris "Next free credits in N days on DATE"
# 3. My Sticker Packs → pack yang ada isinya → thumbnail bukan icon generic
# 4. PackCard layout → nama pack sejajar, padding cukup
# 5. Pack detail → image stiker load instan (dari local cache)
# 6. Missions → Daily Check-in → claim → muncul celebration overlay + day box bounce
```

## Files Touched

| File | Action |
|---|---|
| `lib/data/repositories/credit_transaction_repository.dart` | Edit |
| `lib/presentation/blocs/credit_transactions/credit_transactions_bloc.dart` | Edit |
| `lib/presentation/screens/profile/profile_screen.dart` | Edit |
| `supabase/migrations/20260704000001_subscription_next_grant.sql` | New |
| `lib/data/models/subscription_next_grant.dart` | New |
| `lib/data/repositories/subscription_repository.dart` | Edit |
| `lib/presentation/blocs/subscription/subscription_bloc.dart` | Edit |
| `supabase/migrations/20260704000002_user_packs_first_sticker.sql` | New (if needed) |
| `lib/data/models/sticker_pack.dart` | Edit |
| `lib/data/repositories/sticker_pack_repository.dart` | Edit |
| `lib/presentation/blocs/sticker_pack/sticker_pack_bloc.dart` | Edit |
| `lib/presentation/widgets/pack_card.dart` | Edit |
| `lib/presentation/screens/packs/pack_detail_screen.dart` | Edit |
| `lib/presentation/widgets/lottie_overlay.dart` | New |
| `lib/presentation/screens/missions/widgets/daily_checkin_card.dart` | Edit |
| `lib/presentation/blocs/mission/mission_bloc.dart` | Edit |
| `lib/presentation/screens/missions/missions_screen.dart` | Edit |
| `PROJECT_MEMORY.md` | Edit |

## Proposed Commit Messages (conventional, 1 baris)

```text
fix(profile): broaden earnings filter and show next grant date for subscription
feat(packs): show first sticker as pack thumbnail and tighten card padding
fix(packs): prefer locally cached WebP over network for sticker tiles
feat(missions): add celebration Lottie and day-box bounce on daily check-in
```

## Open Questions / Out of Scope

- Apakah perlu juga menampilkan countdown timer "Next grant in 2d 14h"? Untuk MVP, tampil tanggal absolut saja.
- Apakah `get_user_packs` SQL perlu dimodifikasi, atau lebih baik tambah RPC baru `get_user_packs_with_thumbnail`? Implementor boleh pilih sesuai preferensi; default: tambah field di RPC existing jika tidak breaking.