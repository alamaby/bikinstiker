# Server-Side Legal Consent Audit Plan

Created: 2026-08-02

## Objective

Build server-side consent audit that:
- Binds acceptance to an authenticated or anonymous Supabase user.
- Records version and SHA-256 hash of the exact accepted documents.
- Uses server timestamp, not device time.
- Supports English and Indonesian.
- Blocks app access if server acceptance fails to persist.
- Supports privacy-consent withdrawal as a new event.
- Retains pseudonymous audit proof after account deletion.
- Enforces strict RLS and append-only audit history.

## Scope

- Legal document version registry.
- Pseudonymous legal subject identity.
- Append-only consent event log.
- RPCs for status, acceptance, privacy withdrawal.
- Anonymous Supabase session before consent.
- Remote consent state in Flutter.
- Loading, retry, offline, submission feedback.
- Re-consent when version/hash changes.
- Pseudonymization on account deletion.
- Automated tests (DB, repo, state, UI).
- Operations and retention documentation.

Excludes:
- Final legal-basis determination per processing activity.
- Admin dashboard for audit search.
- Consent export for legal requests.
- Content changes to legal docs beyond version/hash metadata.
- Production deployment via MCP (read-only connection).

## Architecture

### 1. Legal Document Registry `public.legal_document_versions`
- Columns: id, document_type(terms|privacy), version, locale(en|id), content_sha256, effective_at, is_current, created_at.
- Unique `(document_type, version, locale)`; one current per (type, locale).
- 64 lowercase hex content_sha256.
- Old versions kept; never mutated by client.

### 2. Pseudonymous Subject
- `public.legal_audit_subjects(id, created_at)` — no user identity.
- `public.legal_audit_subject_links(user_id PK, subject_id UNIQUE, created_at)` — link to auth.users ON DELETE CASCADE.
- Consent events store subject_id, not auth.user id.

### 3. Append-Only Events `public.legal_consent_events`
- Columns: id, subject_id, action(accepted_bundle|privacy_withdrawn), terms_document_version_id NULL, privacy_document_version_id NOT NULL, locale, app_version, client_request_id, occurred_at, created_at.
- accepted_bundle requires both Terms+Privacy; privacy_withdrawn requires Privacy only.
- Unique (subject_id, client_request_id) idempotency.
- No client INSERT/UPDATE/DELETE. Events never updated.

### 4. RPCs (SECURITY DEFINER, search_path=public, auth.uid()-only)
- get_legal_consent_status(p_locale) -> authoritative status + doc metadata.
- accept_current_legal_documents(...) -> atomic bundle, idempotent by client_request_id, validates current version+hash, returns server occurred_at.
- withdraw_current_privacy_consent(...) -> idempotent new event; Terms unaffected.
- REVOKE ALL on audit tables; grant EXECUTE to authenticated only.

## Milestones
1. Legal semantics.
2. Migration.
3. Flutter repository.
4. Startup auth reorder.
5. Acceptance UX.
6. Withdrawal.
7. Account deletion pseudonymization.
8. Tests.
9. Versioning/verify.
10. Deployment.

## Tasks
- [ ] Finalize legal semantics (contract vs consent vs legitimate interest).
- [ ] Create migration with registry, subjects, events, RPCs, RLS.
- [ ] Rewrite LegalConsentRepository Supabase-backed.
- [ ] Add LegalConsentCubit + states.
- [ ] Reorder startup: language -> session -> remote status -> consent -> onboarding/home.
- [ ] Consent screen: hash verify, blocking retry, server submit.
- [ ] Withdrawal action in Profile.
- [ ] Update soft_delete_account for pseudonymized retention.
- [ ] Add tests.
- [ ] Bump 0.18.0+67 -> 0.19.0+68.
- [ ] flutter pub get / analyze / test / build apk.
- [ ] Supabase local reset + security checks.

## Risks
- Privacy policy vs consent ambiguity.
- Existing users must re-consent.
- Offline blocking.
- Hash newline mismatch.
- Google identity switch severs consent.
- Pseudonymized != anonymized.
- Indefinite retention.
- RPC privilege misconfig.
- App/release version skew.

## Progress Log
- 2026-08-02: Plan written from read-only build.

## Notes
- New migration only; never edit old ones.
</think>

<｜DSML｜tool_calls>
<｜DSML｜invoke name="bash">
<｜DSML｜parameter name="command" string="true">ls supabase/migrations | tail -3