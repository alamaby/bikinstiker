# Security Hardening — Granular RPC/View Privileges (Advisor Triage)

Created: 2026-08-30 11:45:00

## Objective
Eksekusi hasil analisa keamanan + triage Supabase Advisor (56 fungsi SECURITY DEFINER executable anon, 11 SECURITY DEFINER views terbaca anon, 2 search_path mutable). Keputusan owner: **REVOKE granular per fungsi** (eksplisit di katalog), bukan blanket revoke.

## Analisa Kunci (detail di PROJECT_MEMORY)
- Root cause flag meluas: default privileges platform me-re-grant EXECUTE ke anon/authenticated pada setiap `CREATE OR REPLACE` — revoke lama (20260708000024) tersilangkan oleh migrasi berikutnya.
- Terverifikasi aman (ada guard internal): `admin_grant_credits` (current_user), `complete_mission_for_user` (revoke+service_role), `refund_pending_showcase_purchase`/`set_tray_icon`/`soft_delete_account`/`deduct_credit_for_sticker` (auth.uid()).
- Terverifikasi BERCALAH: `acquire/release_generation_lock` (p_user_id arbitrer), `refund_failed_sticker` (tanpa cek kepemilikan), cron functions tanpa guard, `rls_auto_enable` tidak ada di migrasi (dibuat manual — drift).
- Views: agregat bisnis tanpa PII, tapi terbaca anon via PostgREST.
- Fakta pemanfaat: guest = anonymous AUTH user (role `authenticated`) → revoke dari `anon` tidak merusak satu pun alur client.

## Klasifikasi (56 fungsi)
- **Internal-only (21)** — REVOKE anon+authenticated+PUBLIC, GRANT service_role: acquire/release_generation_lock, refund_failed_sticker, complete_mission_for_user, _grant_mission_reward, expire_old_credits, downgrade_expired_subscription, check_and_lock_expired_plus, grant_monthly_credits, handle_pack_slot_downgrade, lock_excess_packs, unlock_packs_on_upgrade (tanpa caller), rls_auto_enable (drift!), admin_grant_credits, handle_new_user, handle_new_user_profile, handle_user_profile_updated_at, _get_or_create_legal_subject, _resolve_legal_consent_status, consume_share_token (EF service-role), get_preset_cost (tanpa caller).
- **Client-authenticated (35)** — REVOKE anon saja: legal consent ×3, check-in ×2, misi, surprise ×3, kredit, packs ×7, feedback ×2, showcase ×11, share token, guest migration ×2, soft_delete_account.
- **Views (11)** — REVOKE SELECT dari anon+authenticated.

## Tasks
- [x] Migrasi `20260830000001_security_hardening.sql` (4 seksi sesuai klasifikasi + search_path ×2 + header maintenance note).
- [x] Docs (plan, TODO checklist verifikasi owner, PROJECT_MEMORY).
- [ ] Deploy owner: `supabase db push` + checklist verifikasi (lihat TODO SK-H).

## Risks
- Signature mismatch → migrasi gagal; signature diambil persis dari metadata advisor (uuid/text/timestamptz/smallint/text[]).
- `CREATE OR REPLACE` di masa depan bisa me-re-grant — header migrasi memerintahkan repeat revoke di migrasi yang sama.
- `rls_auto_enable` body belum ter-audit (drift) — revoke membatasi dampak; audit body menyusul di TODO.

## Progress Log
- 2026-08-30 11:45 — Migrasi dibuat setelah klasifikasi 56 fungsi + verifikasi guard.

## Notes
- Tanpa perubahan kode app/EF; murni SQL privilege. verify_jwt & app keys tidak tersentuh.
- Checklist verifikasi pasca-deploy ada di TODO.md (SQL has_*_privilege + curl anon + smoke app).
