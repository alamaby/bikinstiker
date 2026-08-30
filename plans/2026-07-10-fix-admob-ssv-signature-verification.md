# Fix AdMob SSV Signature Verification

Created: 2026-07-10

## Objective
Fix AdMob SSV callback signature verification. Callbacks with percent-encoded `custom_data` (e.g. `%7B%22userId%22%3A...`) fail ECDSA verification because the signed content is compared against the still-encoded query string instead of the decoded version Google actually signs.

Akar masalah sudah diverifikasi dengan callback produksi:
- Query percent-encoded: signature invalid
- Query percent-decoded: signature valid
- DER-to-raw conversion: valid

## Scope
- Fix canonical content in `admob-ssv/index.ts`: apply `decodeURIComponent` before ECDSA verify.
- Add safe logging for signature failure, grant failure, and dedup.
- Deploy Edge Function.
- Verify new rewarded ad callback on Android.
- Verify Free=2, Plus=3 credit amounts.

## Milestones
1. Fix signature canonicalization
2. Deploy
3. End-to-end validation

## Tasks
- [x] Create plan file
- [ ] Bump patch version and build number in `pubspec.yaml`
- [ ] Fix `admob-ssv/index.ts`: decodeURIComponent on signed content
- [ ] Add safe logging
- [ ] Deploy `supabase functions deploy admob-ssv`
- [ ] Watch new rewarded ad from app
- [ ] Verify invocation HTTP 200
- [ ] Verify `ad_ssv_events` row
- [ ] Verify `user_mission_progress` row
- [ ] Verify `credit_transactions` amount per tier
- [ ] Run `flutter pub get && flutter analyze && flutter test && flutter build apk --split-per-abi`

## Risks
- `decodeURIComponent()` throws on malformed %-encoding; catch and return 401.
- Double-decode must not happen; decode exactly once.
- Callback may arrive >10s after ad watch; polling 10s may still fire "still being verified".
- Replay guard not atomic (SELECT → INSERT race possible under parallel callbacks).
- Public keys rotate; current 1h cache acceptable.

## Progress Log
- 2026-07-10: Plan created; implementation pending.
- 2026-07-10: Akar masalah terverifikasi: encoded query gagal, decoded query valid.
- 2026-07-10: Fix dan logging diimplementasikan.
- 2026-07-10: Deploy terblokir — Supabase CLI belum login (403).
- 2026-07-10: Flutter verify: pub get OK, analyze OK (1 pre-existing warning), test 121/121 OK.

## Notes
Proposed commit message: `fix(admob): verify SSV signatures against decoded callback content`
