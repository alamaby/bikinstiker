import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
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
  final _formKey = GlobalKey<FormState>();

  bool get _isGuestWall => widget.mode == AuthScreenMode.guestAuthWall;

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
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
                          state.errorMessage!,
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  const Text(
                    'AI-powered WhatsApp sticker generator',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  if (_isGuestWall) ...[
                    _GuestAuthWallHeader(hasGuestResult: hasGuestResult),
                    const SizedBox(height: 24),
                  ] else ...[
                    TabBar(
                      controller: _tab,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.black54,
                      tabs: const [
                        Tab(text: 'Sign in'),
                        Tab(text: 'Sign up'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Min 6 characters'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: submitting ? null : _submit,
                    icon: submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      submitting ? 'Please wait...' : _submitButtonLabel,
                    ),
                  ),
                  if (_isGuestWall && !submitting) ...[
                    const SizedBox(height: 16),
                    _GuestWallWarning(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String get _submitButtonLabel {
    if (_isGuestWall) {
      return _tab.index == 0
          ? 'Create account and keep sticker'
          : 'Sign in to existing account';
    }
    return _tab.index == 0 ? 'Sign in' : 'Create account';
  }
}

class _GuestAuthWallHeader extends StatelessWidget {
  final bool hasGuestResult;

  const _GuestAuthWallHeader({required this.hasGuestResult});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasGuestResult ? 'Save your sticker' : 'Create an account',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          hasGuestResult
              ? 'You\'ve generated a sticker as a guest. Create an account to save and share it.'
              : 'Create an account to save and share your stickers.',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _GuestWallWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              'Guest stickers cannot be moved to an existing account. '
              'If you continue signing in, this guest sticker will be discarded.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
