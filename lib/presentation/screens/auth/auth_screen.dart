import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/sticker_gen/sticker_gen_bloc.dart';

enum AuthScreenMode { normal, guestAuthWall }

class AuthScreen extends StatefulWidget {
  final AuthScreenMode mode;

  const AuthScreen({super.key, this.mode = AuthScreenMode.normal});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailMarketing = false;

  bool get _isGuestWall => widget.mode == AuthScreenMode.guestAuthWall;
  bool get _isSignUp => _isGuestWall ? _tab.index == 0 : _tab.index == 1;

  @override
  void initState() {
    super.initState();
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (_isGuestWall) {
      if (_tab.index == 0) {
        // Create account and keep sticker
        auth.add(AuthSignUpRequested(email, pass, upgradeGuest: true));
      } else {
        // Sign in existing account - will discard guest sticker
        auth.add(AuthSignInRequested(email, pass, isGuestAuthWall: true));
      }
    } else {
      if (_tab.index == 0) {
        auth.add(AuthSignInRequested(email, pass));
      } else {
        auth.add(AuthSignUpRequested(email, pass));
      }
    }
  }

  void _googleSignIn() {
    context.read<AuthBloc>().add(
      AuthGoogleSignInRequested(upgradeGuest: _isGuestWall),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stickerGen = context.watch<StickerGenBloc>();
    final hasGuestResult = _isGuestWall && stickerGen.state.signedUrl != null;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthBlocState>(
          listenWhen: (p, n) =>
              p.status != n.status ||
              p.errorMessage != n.errorMessage ||
              p.infoMessage != n.infoMessage,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated ||
                state.status == AuthStatus.guest) {
              if (_isGuestWall && mounted) {
                Navigator.of(context).pop();
                return;
              }
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.error,
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          safeErrorMessage(l10n, state.errorMessage),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state.infoMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.infoMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final submitting = state.status == AuthStatus.submitting;
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        Row(
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'BikinStiker',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tagline,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 32),
                        if (_isGuestWall) ...[
                          _GuestAuthWallHeader(
                            hasGuestResult: hasGuestResult,
                            isSignUp: _isSignUp,
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          TabBar(
                            controller: _tab,
                            indicatorColor: AppColors.primary,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: Colors.black54,
                            tabs: [
                              Tab(text: l10n.signIn),
                              Tab(text: l10n.signUp),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon: const Icon(
                                      Icons.alternate_email,
                                    ),
                                  ),
                                  validator: (v) =>
                                      v == null || !v.contains('@')
                                      ? l10n.emailInvalid
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: true,
                                  autofillHints: [
                                    _isSignUp
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.done,
                                  onEditingComplete: _submit,
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (v) => v == null || v.length < 6
                                      ? l10n.passwordMin
                                      : null,
                                ),
                                if (_isSignUp) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _displayNameCtrl,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    autofillHints: const [AutofillHints.name],
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: l10n.displayNameOptional,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _emailMarketing,
                                        onChanged: (v) {
                                          setState(
                                            () => _emailMarketing = v ?? false,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          l10n.sendTips,
                                          style: const TextStyle(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: submitting ? null : _submit,
                          icon: submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            submitting
                                ? l10n.pleaseWait
                                : _submitButtonLabel(l10n),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                l10n.or,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: submitting ? null : _googleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: Text(
                            _isGuestWall
                                ? l10n.continueWithGoogleKeep
                                : l10n.continueWithGoogle,
                          ),
                        ),
                        if (_isGuestWall && !submitting) ...[
                          const SizedBox(height: 16),
                          _GuestWallWarning(),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => _tab.index = _isSignUp ? 1 : 0,
                              child: Text(
                                _isSignUp
                                    ? l10n.alreadyHaveAccount
                                    : l10n.newHere,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _submitButtonLabel(AppLocalizations l10n) {
    if (_isGuestWall) {
      return _tab.index == 0
          ? l10n.createAccountKeepSticker
          : l10n.signInExistingAccount;
    }
    return _tab.index == 0 ? l10n.signIn : l10n.createAccount;
  }
}

class _GuestAuthWallHeader extends StatelessWidget {
  final bool hasGuestResult;
  final bool isSignUp;

  const _GuestAuthWallHeader({
    required this.hasGuestResult,
    required this.isSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSignUp
              ? (hasGuestResult
                    ? l10n.saveYourSticker
                    : l10n.createAccount)
              : l10n.signInExistingAccount,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          isSignUp
              ? (hasGuestResult
                    ? l10n.guestSaveWarning
                    : l10n.guestCreateAccountDesc)
              : l10n.guestSignInDesc,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _GuestWallWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.guestWallWarning,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
