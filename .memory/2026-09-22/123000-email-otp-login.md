# Email OTP Login Implementation

Date: 2026-09-22
Topic: email-otp-login

## Task
Implement email OTP login (8-digit code) as alternative sign-in flow alongside existing password/Google/guest. `shouldCreateUser=false`, guest wall OTP allowed but stickers may be lost by design.

## Files Changed
- `lib/data/repositories/auth_repository.dart` — added `sendEmailOtp` + `verifyEmailOtp` to interface and impl
- `lib/presentation/blocs/auth/auth_bloc.dart` — added `AuthOtpSendRequested`, `AuthOtpVerifyRequested` events; `pendingOtpEmail` state field; `_onOtpSend` and `_onOtpVerify` handlers
- `lib/core/errors/safe_error_message.dart` — added 4 OTP error branches (otp_disabled, otp_expired, rate_limit, invalid_otp)
- `lib/presentation/screens/auth/otp_verify_screen.dart` — **new** 8-digit OTP verify screen with 60s resend cooldown
- `lib/presentation/screens/auth/auth_screen.dart` — added OTP button, import, listener navigation
- `lib/l10n/app_en.arb` + `lib/l10n/app_id.arb` — 13 new OTP keys + regenerated localizations
- `test/auth_bloc_otp_test.dart` — **new** 6 bloc tests
- `test/safe_error_message_test.dart` — added 4 OTP mapping tests

## Decisions
- `shouldCreateUser: false` enforced at repo layer; new emails rejected at send step (no OTP screen shown)
- Guest wall OTP failure preserves `guest` status (regression guard for legal-consent bounce)
- `pendingOtpEmail` retained on verify failure so user can resend without retyping email
- No custom DB table or edge function for OTP; uses native Supabase Auth OTP flow
- 8-digit code consistent across app and Dashboard config (S8 pending manual config)

## Blockers
- S8 (Dashboard config): OTP length must be set to 8, template must contain `{{ .Token }}`, SMTP via Resend configured. Owner to complete.

## Verification
- `flutter analyze` — 0 issues
- `flutter test` — 218 passed (baseline 208 + 10 new)
- Full test suite clean, no regressions

## Commit Proposal
`feat(auth): add email OTP login with 8-digit code`

## Related
- Plan: `plans/2026-09-22-email-otp-login-plan.md`
- Reference impl: `bagistruk/lib/presentation/auth/screens/verify_otp_screen.dart`
