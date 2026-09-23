# Email OTP Templates (BikinStiker Version)

Date: 2026-09-23
Topic: email-otp-templates

## Task

Buatkan versi BikinStiker dari template email `Confirm signup` dan `Magic Link`
yang sebelumnya di-copy dari sibling repo bagistruk.

## Files Changed

- `supabase/templates/auth-confirm-signup.html` — **new**, adaptasi 1:1 dari
  `bagistruk/supabase/templates/auth-confirm-signup.html` dengan brand diganti
- `supabase/templates/auth-magic-link.html` — **new**, adaptasi 1:1 dari
  `bagistruk/supabase/templates/auth-magic-link.html` dengan brand diganti

## Decisions

- Layout HTML dipertahankan identik (table-based, inline styles) agar
  kompatibilitas email client sama dengan yang sudah terbukti di bagistruk.
- Hanya teks brand yang diganti (BagiStruk → BikinStiker); placeholder
  `{{ .Token }}` dan `{{ .ConfirmationURL }}` dibiarkan persis apa adanya.
- Teks expiry "1 hour" dipertahankan agar konsisten dengan default Dashboard;
  bila owner set expiry berbeda, teks ini harus disesuaikan manual.
- Tidak buat `auth-email-change.html` karena alur OTP bikinstiker
  (`shouldCreateUser=false`, tanpa link/upgrade email) tidak memakainya.

## Assumptions / Risks

- Panjang kode ditentukan setting OTP length Dashboard (=8), bukan template.
- Template ini hanya source-of-truth lokal; yang live adalah yang di-paste ke
  Dashboard → Authentication → Email Templates (masih manual, owner).

## Blockers

- Paste kedua file ke Dashboard (owner, manual).

## Verification

- Grep `{{ .Token }}` / `{{ .ConfirmationURL }}`: 6 matches (3 per file).
- Grep `BagiStruk|bagistruk`: 0 matches (tidak ada sisa brand lama).

## Commit Proposal

`feat(auth): add BikinStiker email OTP templates`

## Related

- Plan: `plans/2026-09-22-email-otp-login-plan.md` (S8)
- Reference: `bagistruk/supabase/templates/`
