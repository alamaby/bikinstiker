# Surprise-Me Subject Twist Expansion Plan

Created: 2026-09-19 00:00:00

## Objective

Perbesar base pool `surprise-me` dari 60 subjek / 41 twist menjadi ~127 subjek / ~86 twist (+112 string baru: manusia umum, stylish, profesi real, profesi video game generik, khas Indonesia) tanpa mengubah logika handler, guidance, limit, kuota, atau rate-limit.

## Scope

- IN: `supabase/functions/surprise-me/index.ts` — array `SUBJECTS` dan `TWISTS` saja.
- IN: `supabase/functions/surprise-me/index_test.ts` — tambah 2 test guard (duplikat + panjang/style-word).
- OUT: `buildSurpriseSeed`, `buildSurpriseGuidance`, `MAX_PROMPT_CHARS`, rate-limit, quota/charge/refund, `generate-sticker`, `kPromptSuggestions`, `surprise_theme`, migrasi DB, Flutter/`pubspec.yaml`. Tidak ada deploy otomatis (manual oleh owner).

## Milestones

1. Ekspansi array (satu file, copy-paste aman).
2. Guard test + verifikasi lokal hijau.
3. Serah terima deploy manual + smoke.

## Tasks

- [x] 1. Baca `supabase/functions/surprise-me/index.ts:115-155` — pahami format entri (`"a ..."`, koma, `pickRandom` via `crypto.getRandomValues`).
- [x] 2. Tambahkan 67 subjek ke `SUBJECTS` (append setelah `"a skateboard"`, jaga trailing comma). Daftar verbatim:
  ```ts
  // manusia umum (+15)
  "a toddler in a onesie", "a little girl with pigtails", "a little boy with a cap",
  "a teenage girl", "a teenage boy", "a young woman", "a young man",
  "an elderly grandmother", "an elderly grandfather", "a baby wrapped in a blanket",
  "a father and child", "a mother and child", "a group of best friends",
  "a sleepy office worker", "a happy hiker",
  // stylish (+12) — ADITIF, jangan hapus/ganti yang di atas
  "an elegant woman", "a chic young woman", "a macho man", "an emo boy",
  "a glamorous diva", "a punk girl", "a goth boy", "a hipster young man",
  "a classy old gentleman", "a stylish hijab woman", "a dapper groom", "a graceful ballerina",
  // profesi real (+15)
  "a doctor", "a nurse", "a firefighter", "a police officer", "a pilot", "a sailor",
  "a farmer", "a fisherman", "a chef", "a barista", "a teacher", "a scientist",
  "a construction worker", "a delivery courier", "a photographer",
  // profesi game generik (+15) — arketipe saja, DILARANG nama IP (Mario/Pokemon/dll)
  "a paladin", "a mage", "a necromancer", "an elven archer", "a stealth assassin",
  "a party healer", "a mech pilot", "a space marine", "a dungeon explorer", "a sniper",
  "a racing driver", "a battle royale survivor", "a speedrunner with a headset",
  "a cozy farm sim villager", "a retro platformer hero",
  // khas ID subjek (+10)
  "a becak driver", "a jamu seller", "a sate vendor", "a batik artisan", "a dangdut singer",
  "a pencak silat fighter", "an ondel-ondel performer", "a barong dancer",
  "a baby orangutan", "a komodo ranger",
  ```
- [x] 3. Tambahkan 45 twist ke `TWISTS` (append setelah `"holding a mini Monas"`). Daftar verbatim:
  ```ts
  // umum (+35)
  "blowing a kiss", "giving a thumbs up", "facepalming", "shrugging playfully",
  "peeking from behind", "jumping with joy", "doing a backflip", "breakdancing",
  "doing karate", "doing ballet", "playing drums", "playing violin", "painting a canvas",
  "taking a selfie", "video-calling a friend", "streaming with a headset",
  "coding on a laptop", "watering plants", "walking a dog", "riding a scooter",
  "riding a horse", "camping in a tent", "having a picnic", "blowing bubbles",
  "catching fireflies", "building a sandcastle", "napping in a hammock",
  "flying a paper plane", "balancing on one foot", "spinning happily",
  "crying with laughter", "hiding under a blanket", "sharing snacks",
  "waving goodbye", "cheering loudly",
  // khas ID (+10)
  "wearing a songkok", "wearing an udeng", "carrying a tampah of jajan pasar",
  "holding es cendol", "holding es teh manis", "playing gamelan", "playing kolintang",
  "doing pencak silat", "surfing in Bali", "climbing a volcano trail",
  ```
- [x] 4. Validasi manual sebelum test: (a) tidak ada duplikat case-insensitive; (b) tidak ada substring `Suggest ONE`; (c) tidak ada kata style (`pixel, clay, origami, neon, watercolor, stained glass, embroidery, risograph, voxel, lego, doodle, chibi, kawaii, vector, photoreal, caricature, chrome, graffiti`); (d) subjek diawali `a/an`, twist partisipel, tiap entri ≤30 char.
- [x] 5. Tambah 2 test di `index_test.ts`: (a) `no duplicate SUBJECTS/TWISTS` — baca source via `Deno.readTextFile`, ekstrak string array, assert set size == list size; (b) `new entries respect length and style-word rules` — assert tiap entri tidak mengandung kata style di atas dan panjang ≤40 char. Ikuti pola contract test existing (butuh `--allow-read`).
- [x] 6. Verifikasi lokal (dari repo root):
  ```
  cd supabase/functions/surprise-me
  deno check index.ts
  deno test --allow-read index_test.ts
  ```
  Kriteria: check bersih; test 17/17 hijau (15 existing + 2 baru). Jika gagal, perbaiki entri/test — JANGAN ubah logika handler.
- [ ] 7. Sampling seed (opsional tapi disarankan): panggil `buildSurpriseSeed()` 50x, pastikan bervariasi dan tidak ada seed diawali `suggest one fresh` (test existing sudah cover).
- [ ] 8. Serah terima manual (JANGAN eksekusi deploy): owner jalankan `supabase functions deploy surprise-me` lalu smoke 3x (umum / profesi / ID) dan cek `surprise_me_history`. Tidak perlu `supabase db push` (tanpa migrasi) dan tidak perlu bump `pubspec.yaml` (backend-only).

## Risks

- Seed panjang + ekspansi LLM → retry `prompt_too_long` (>200 char) naik. Mitigasi: batas ≤30 char/entri sudah di task 4; retry 1x existing menanganinya.
- Nama karakter game ber-IP → risiko merek. Mitigasi: arketipe generik saja; tolak nama spesifik saat review.
- Kombinasi budaya ganda (mis. `stylish hijab woman wearing songkok`). Diterima — guidance membiarkan LLM ganti subjek bila tidak cocok; jangan tambah aturan baru.

## Progress Log

- 2026-09-19 00:00:00 — Plan dibuat dari diskusi paket besar 100+ (base pool saja, stylish aditif). Belum ada edit kode; siap dieksekusi model lanjutan.
- 2026-09-19 09:00:00 — Tasks 1-6 selesai. SUBJECTS 60→127, TWISTS 41→86. 2 test guard baru ditambahkan (`pool: no duplicate...` dan `pool: new entries respect...`). `deno check` bersih, `deno test` 17/17 hijau. Sampling 50 seed — semua unik, variasi mencakup kategori baru (profesi/game/ID).

## Notes

- Referensi struktur: `surprise-me/index.ts:46-49` (limit/avoid), `:147-183` (seed+guidance), `:419-473` (failover+strip+validasi); strip hanya hapus frasa ≥2 kata (`generate-sticker/index.ts:347-372`) sehingga `elegant/chic/macho/emo` tunggal aman.
- Skala kecil (satu EF, tanpa skema DB) — standar arsitektur diterapkan proporsional tanpa seremoni enterprise (TOGAF ADM tidak diinstansiasi penuh untuk fitur ini).
- Contoh seed baru yang diharapkan: `an elegant woman playing gamelan`, `a mech pilot surfing in Bali`, `a becak driver giving a thumbs up`.
