import '../presentation/blocs/auth/auth_bloc.dart';

/// Decides whether [_AuthGate] should auto-spawn an anonymous session.
///
/// Returns false after an explicit sign-out so the user lands on the
/// login screen instead of being silently re-logged in as guest.
/// Fresh starts (never signed out) still auto-spawn a guest.
bool shouldAutoSpawnGuest(AuthBlocState state) {
  if (state.status != AuthStatus.unauthenticated) return false;
  return !state.explicitSignOut;
}
