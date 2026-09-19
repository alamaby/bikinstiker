# Surprise-me pool expansion (60→127 subjects, 41→86 twists)

## Task
Perbesar base pool `surprise-me` dari 60 subjek / 41 twist menjadi ~127 / ~86 (+112 string baru) tanpa mengubah logika handler.

## Files changed
- `supabase/functions/surprise-me/index.ts` — append 67 SUBJECTS + 45 TWISTS
- `supabase/functions/surprise-me/index_test.ts` — +2 test guard (duplikat + style-word/panjang pada entri baru saja)
- `plans/2026-09-19-surprise-me-subject-twist-expansion-plan.md` — progress log updated

## Key decisions
- New entries appended **after** existing ones; original pool indices unchanged (60 subjects, 41 twists preserved as baseline).
- Test guard only checks *new* entries by slicing at known offsets (`ORIG_SUBJECTS=60`, `ORIG_TWISTS=41`) — avoids false-positive on pre-existing `"an origami crane"`.
- No DB migration, no `pubspec.yaml` bump, no deploy executed (plan task 8 = manual by owner).

## Verification
- `deno check index.ts` — clean
- `deno test --allow-env --allow-read --allow-net --config deno.json index_test.ts` — **17/17 hijau** (15 existing + 2 baru)
- Sampling 50x `buildSurpriseSeed()` — 50 unique seeds, campuran kategori baru (profesi/game/ID) terverifikasi visual

## Blockers / follow-up
- Task 7 (sampling seed) sudah diverifikasi manual; tinggal ditanda task 8: owner jalankan `supabase functions deploy surprise-me` lalu smoke test.

## Commit proposal
`feat(surprise-me): expand pool to 127 subjects and 86 twists with dedup/style guards`
