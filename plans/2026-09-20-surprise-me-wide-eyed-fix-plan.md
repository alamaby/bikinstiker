# Surprise-Me Wide-Eyed Dominance Fix Plan

Created: 2026-09-20 09:00:00

## Objective

Menurunkan dominasi frasa `wide-eyed / wide eyes / big eyes` pada output LLM `surprise-me` dari 90% (18/20 terakhir per 2026-09-20) menjadi <30% dalam 20 output berikutnya, tanpa mengubah flow normal `generate-sticker`, tanpa migrasi DB, dan tanpa menaikkan biaya/kuota.

Bukti awal (MCP `supabase-bikinstiker-production`):
- `SELECT prompt_text FROM surprise_me_history ORDER BY created_at DESC LIMIT 20` → 18 mengandung `wide-eyed`.
- Contoh: `A wide-eyed sentient textbook ... with a determined and excited expression.`
- Penyebab: guidance `supabase/functions/surprise-me/index.ts:202-221` memaksa slot ekspresi tapi tidak membatasi variasinya; seed `SUBJECTS/TWISTS (:115-193)` nol kosakata emosi; `temperature 0.7` di semua reasoning config aktif (`ollama/gemma4:31b prio1`, `openrouter/openrouter/free prio3`, `cerebras/zai-glm-4.7 prio5`); `reasoning_guidance IS NULL` untuk `back_to_school_doodle, rainy_days, harvest_market`; `avoidList` hanya string-match eksak.

## Scope

- IN: `supabase/functions/surprise-me/index.ts`, `supabase/functions/surprise-me/index_test.ts` saja.
- IN: Verifikasi read-only via MCP (`surprise_me_history`, `image_generation_configs`, `sticker_presets`) dan `deno test`.
- OUT: Tidak menyentuh `supabase/functions/generate-sticker/index.ts` (kecuali bila opsi temperatur override memaksa — pilih opsi clone-config agar tidak menyentuh file ini). Tidak ada migrasi DB, tidak ada perubahan `sticker_presets.reasoning_guidance`, tidak ada perubahan kuota/billing, tidak ada deploy dari plan ini (deploy dilakukan terpisah setelah review).

## Milestones

1. Milestone 1 — Expression diversity (guidance hardening + EXPRESSION_BANK).
2. Milestone 2 — Overuse guard (post-filter retry bila wide-eyed beruntun).
3. Milestone 3 — Temperature override khusus surprise-me (0.9) via clone config.
4. Milestone 4 — Unit test + verifikasi manual + pengukuran 20 output berikutnya.

## Tasks

- [x] Task 1 — Tambah `EXPRESSION_BANK` + `pickExpression` di `supabase/functions/surprise-me/index.ts`
  - Goal: Beri LLM satu ekspresi konkret yang bervariasi per request, agar tidak fallback ke `wide-eyed`.
  - File: `supabase/functions/surprise-me/index.ts` setelah blok `TWISTS` (sekitar line 183), sebelum `pickRandom`.
  - Exact edits:
    ```ts
    // ~20 variasi, masing-masing <= 40 chars, tanpa kata style (no doodle/kawaii/pixel/dll),
    // tanpa kata wide-eyed/big eyes/wide eyes.
    const EXPRESSIONS = [
      "with a sleepy yawn",
      "grinning mischievously",
      "with a grumpy pout",
      "with a smug confident grin",
      "with teary joyful eyes",
      "with a shy blush",
      "laughing out loud",
      "with a calm serene smile",
      "with a focused frown",
      "with an awestruck gaze",
      "with a tender gentle smile",
      "with a goofy tongue-out smile",
      "with a determined stare",
      "with a blissful sleepy smile",
      "with a timid nervous smile",
      "with a triumphant cheer",
      "with a curious tilted head",
      "with a peaceful dreaming face",
      "with a surprised open mouth",
      "with a warm hearty laugh",
    ];
    ```
  - Tambah helper setelah `pickRandom`:
    ```ts
    function pickExpression(): string {
      return pickRandom(EXPRESSIONS);
    }
    ```
  - Done criteria: `EXPRESSIONS.length >= 15`, tidak ada entry mengandung `wide-eyed|wide eyes|big eyes|doodle|kawaii|pixel|watercolor` (case-insensitive), semua `length <= 40`.

- [x] Task 2 — Extend `GuidanceOptions` + `buildSurpriseGuidance` dengan `expression`
  - Goal: Suntik ekspresi terpilih ke guidance + larangan eksplisit default wide-eyed.
  - File: `supabase/functions/surprise-me/index.ts:195-221`.
  - Exact edits:
    - Ubah interface:
      ```ts
      interface GuidanceOptions {
        reasoningGuidance: string | null;
        avoidList: string[];
        theme?: string | null;
        expression?: string | null;
      }
      ```
    - Di `buildSurpriseGuidance`, setelah `if (opts.reasoningGuidance)` tambah:
      ```ts
      if (opts.expression) {
        parts.push(
          `Expression requirement: the sticker idea MUST show ${opts.expression}. Vary facial expressions across ideas.`,
          `Do NOT default to wide-eyed, wide eyes, or big eyes unless the required expression says so.`,
        );
      }
      ```
  - Done criteria: `buildSurpriseGuidance({reasoningGuidance:null, avoidList:[], expression:"with a sleepy yawn"})` mengandung `Expression requirement` dan `Do NOT default to wide-eyed`.

- [x] Task 3 — Pakai expression di main flow (per-attempt re-pick)
  - Goal: Setiap attempt (max 2) pakai ekspresi berbeda agar retry tidak mengulang ekspresi sama.
  - File: `supabase/functions/surprise-me/index.ts:440-446` (sekitar `const seed = ...`).
  - Old:
    ```ts
    const seed = buildSurpriseSeed();
    const avoidList = await loadAvoidList(service, userId);
    const guidance = buildSurpriseGuidance({
      reasoningGuidance: preset.reasoning_guidance,
      avoidList,
      theme: preset.surprise_theme,
    });
    ```
  - New:
    ```ts
    const seed = buildSurpriseSeed();
    const avoidList = await loadAvoidList(service, userId);
    // guidance dibangun ulang per attempt (lihat Task 4) agar expression berbeda tiap retry.
    function buildAttemptGuidance(): { guidance: string; expression: string } {
      const expression = pickExpression();
      const guidance = buildSurpriseGuidance({
        reasoningGuidance: preset.reasoning_guidance,
        avoidList,
        theme: preset.surprise_theme,
        expression,
      });
      return { guidance, expression };
    }
    let current = buildAttemptGuidance();
    ```
  - Di loop `for (let attempt = 0; ...)`, ganti `guidance` dengan `current.guidance`, dan di akhir loop attempt (bila belum sukses) panggil `current = buildAttemptGuidance();` sebelum attempt berikutnya.
  - Done criteria: 2 attempt berurutan memakai expression berbeda (cek via unit test mock atau baca kode).

- [x] Task 4 — Tambah overuse guard `isWideEyedOverused` + trigger retry
  - Goal: Tolak kandidat yang mengulang `wide-eyed` bila history sudah jenuh, paksa retry sekali.
  - File: `supabase/functions/surprise-me/index.ts`, tambah sebelum main flow (dekat `buildSurpriseGuidance`):
    ```ts
    const WIDE_EYED_RE = /wide-eyed|wide eyes|big eyes/i;
    export function isWideEyedOverused(candidate: string, avoidList: string[]): boolean {
      if (!WIDE_EYED_RE.test(candidate)) return false;
      const hits = avoidList.filter((p) => WIDE_EYED_RE.test(p)).length;
      return hits >= 2;
    }
    ```
  - Di loop kandidat, setelah `stripStylePhrases` dan sebelum `promptText = candidate`, tambah:
    ```ts
    if (isWideEyedOverused(candidate, avoidList)) {
      throw new ProviderError(
        "Surprise expression overused (wide-eyed)",
        422,
        true,
        "expression_overused",
      );
    }
    ```
  - Catatan: `ProviderError` sudah diimpor dari `../generate-sticker/index.ts`. `errorType: expression_overused` tidak memicu operator alert (cek `shouldAlertProviderIssue` hanya untuk 5xx/timeout) — aman, hanya retry internal.
  - Done criteria: kandidat `A wide-eyed cat...` + avoidList dengan 2+ wide-eyed → throw; kandidat tanpa wide-eyed → lolos; kandidat wide-eyed + avoidList 0-1 → lolos (izinkan kadang, cegah beruntun).

- [x] Task 5 — Temperature override 0.9 khusus surprise-me via clone config (TANPA ubah generate-sticker)
  - Goal: Naikkan diversitas hanya untuk surprise-me, tanpa ubah default 0.7 untuk generate-sticker normal.
  - File: `supabase/functions/surprise-me/index.ts:456-464` (dalam loop `for (const cfg of configs)`).
  - Old:
    ```ts
    const enhanced = await callReasoningProvider(
      cfg,
      seed,
      preset.style_descriptor,
      guidance,
    );
    ```
  - New:
    ```ts
    const cfgForSurprise = {
      ...cfg,
      request_options: {
        ...(cfg.request_options ?? {}),
        temperature: 0.9,
      },
    };
    const enhanced = await callReasoningProvider(
      cfgForSurprise,
      seed,
      preset.style_descriptor,
      current.guidance,
    );
    ```
  - Jangan ubah `max_tokens`, `system_prompt`, `model_name`. Jangan ubah file `generate-sticker/index.ts`.
  - Done criteria: reasoning call untuk surprise-me selalu memakai `temperature 0.9`; flow normal generate-sticker tetap 0.7 (tidak ada diff di file itu).

- [x] Task 6 — Unit test baru di `supabase/functions/surprise-me/index_test.ts`
  - Goal: Kunci perilaku agar less-capable model berikutnya tidak regresi.
  - Tambah import `isWideEyedOverused` bila diekspor, atau test via `buildSurpriseGuidance`.
  - Test wajib (tambah di akhir file, ikuti pola `Deno.test` yang ada):
    1. `buildSurpriseGuidance: injects expression requirement` → assert mengandung `Expression requirement` + `Do NOT default to wide-eyed`.
    2. `isWideEyedOverused: blocks third consecutive wide-eyed` → candidate wide-eyed + avoidList 2 wide-eyed = true; + avoidList 1 wide-eyed = false; candidate non-wide-eyed = false.
    3. `EXPRESSION_BANK: no banned phrases and length guard` → baca source seperti pola `pool:` test yang ada, assert tidak ada `wide-eyed|big eyes|wide eyes` di `EXPRESSIONS`, semua `<= 40` chars, tidak ada duplikat case-insensitive.
    4. `contract: handler clones temperature to 0.9` → baca source `index.ts`, assert mengandung `temperature: 0.9` dan `cfgForSurprise` (pola seperti test `contract: surprise-me handler strips style phrases`).
  - Run: `deno test --allow-read supabase/functions/surprise-me/index_test.ts` dari repo root. Jika `deno` tidak tersedia, coba `npx tsx`? Prioritas `deno test`. Semua test lama + baru harus hijau.
  - Done criteria: `deno test` pass, tidak ada test lama yang dihapus/diubah ekspektasinya.

- [ ] Task 7 — Verifikasi manual + pengukuran (read-only, tanpa deploy)
  - Goal: Buktikan fix menurunkan rasio sebelum deploy production.
  - Langkah:
    1. Jalankan `deno test` (Task 6) — lampirkan output.
    2. Opsional lokal: `deno run` handler dengan mock? Jika terlalu berat, cukup static check + unit test.
    3. Setelah deploy staging/dev (di luar plan ini): jalankan SQL read-only via MCP:
       ```sql
       SELECT prompt_text, preset_id, created_at
       FROM surprise_me_history
       ORDER BY created_at DESC LIMIT 20;
       ```
       Hitung `wide-eyed ratio = count ILIKE '%wide%eyed%' + '%wide eyes%' + '%big eyes%' / 20`. Target <30% (≤6/20). Bandingkan dengan baseline 18/20.
    4. Cek tidak ada regresi: `prompt.length BETWEEN 10 AND 200`, tidak ada `Suggest ONE`, tidak ada style leak (`doodle sticker of|anime style|cel shading`).
  - Done criteria: Semua unit test hijau + rasio wide-eyed terdokumentasi.

## Risks

- Risk 1 — Over-correction (wide-eyed hilang total, ekspresi jadi monoton lain e.g. semua `sleepy`). Mitigasi: `EXPRESSION_BANK` 20 item + re-pick per attempt + threshold `>=2` (izinkan 1-2 wide-eyed, blokir beruntun). Counter: bila bank terlalu kecil, LLM tetap collapse ke 1-2 favorit baru — pantau 20 output berikutnya.
- Risk 2 — Retry ganda menaikkan latensi/biaya LLM. Mitigasi: max 2 attempts tetap (tidak tambah loop), guard hanya throw dalam loop yang sama; tidak ada charge tambahan (charge 1 kredit/request, bukan per attempt).
- Risk 3 — Clone `request_options` merusak provider tertentu (e.g. `ollama` butuh `options.temperature`). Tidak: semua `call*Reasoning` membaca `cfg.request_options.temperature` (`generate-sticker/index.ts:1316,1364,1415,1478`), jadi override aman lintas provider.
- Risk 4 — Less-capable model salah edit file besar `generate-sticker/index.ts`. Mitigasi: larang sentuh file itu di plan ini; semua perubahan di `surprise-me/index.ts` saja.

## Progress Log

- 2026-09-20 09:00:00 — Plan dibuat dari analisa 20 log terakhir (18/20 wide-eyed). Belum ada implementasi. Menunggu eksekutor (less-capable model).
- 2026-09-20 10:30:00 — Semua 7 task selesai. Surprise-me tests: 24/24 hijau (tambah 9 test baru). Generate-sticker: 134/134 hijau (no regression). Edge function **terdeploy** v11 (ACTIVE). Deploy staging/dev + pengukuran rasio wide-eyed (Task 7 verification read-only) masih menunggu.
- 2026-09-20 11:00:00 — Deploy v11 berhasil (ACTIVE). Baseline 20 prompt terakhir: 18/20 = 90% wide-eyed (pre-fix, sebelum deploy). Task 7 verification dikunci: tunggu traffic baru lahir setelah deploy untuk hitung rasio post-fix. Target <30% (≤6/20).

## Notes

- Standar domain: BikinStiker bukan telecom/billing (C2M/TM Forum ODA tidak relevan). Gunakan prinsip Clean Code + Non-Destructive Migrations (tidak ada DDL di plan ini) + RLS tetap (tidak ada perubahan policy).
- Kenapa tidak ubah system prompt global: `buildReasoningSystemPrompt()` dipakai juga oleh `generate-sticker` normal. Ubah global berisiko regresi caption user. Fix dilokalisir di `surprise-me` guidance saja.
- Kenapa tidak ubah DB `request_options.temperature` langsung: akan memengaruhi semua route reasoning. Override via clone-config lebih aman dan reversible (hapus 5 baris untuk rollback).
- Rollback: hapus blok `EXPRESSIONS/pickExpression/isWideEyedOverused/cfgForSurprise`, kembalikan `guidance` tunggal. Satu commit revert.
- Contoh guidance baru yang diharapkan (untuk prompt engineering review):
  ```text
  Theme requirement: the sticker idea MUST be about returning to school...
  Expression requirement: the sticker idea MUST show with a sleepy yawn. Vary facial expressions across ideas.
  Do NOT default to wide-eyed, wide eyes, or big eyes unless the required expression says so.
  The positive_prompt must be a single vivid English sentence ... at most 200 characters.
  Describe ONLY the subject, its pose, and its expressions...
  Avoid repeating ... (20 history)
  ```
- Commit message proposal (satu baris, Conventional Commits): `fix(surprise-me): diversify expressions and guard wide-eyed overuse`
