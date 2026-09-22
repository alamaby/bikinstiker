import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/auth_bloc.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final bool isGuestAuthWall;

  const OtpVerifyScreen({
    super.key,
    required this.email,
    this.isGuestAuthWall = false,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const int _otpLength = 8;
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  Timer? _timer;
  bool _verifying = false;
  bool _resending = false;
  int _cooldown = 60;

  bool get _busy => _verifying || _resending;

  @override
  void initState() {
    super.initState();
    _startCooldown(rebuild: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _startCooldown({bool rebuild = true}) {
    _timer?.cancel();
    if (rebuild) {
      setState(() => _cooldown = 60);
    } else {
      _cooldown = 60;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown--);
    });
  }

  void _verify() {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    context.read<AuthBloc>().add(
      AuthOtpVerifyRequested(
        widget.email,
        _otp.text.trim(),
        isGuestAuthWall: widget.isGuestAuthWall,
      ),
    );
  }

  void _resend() {
    if (_busy || _cooldown > 0) return;
    setState(() => _resending = true);
    context.read<AuthBloc>().add(
      AuthOtpSendRequested(widget.email, isGuestAuthWall: widget.isGuestAuthWall),
    );
  }

  String? _validateOtp(String? value) {
    final code = value?.trim() ?? '';
    if (code.length != _otpLength) return AppLocalizations.of(context)!.otpInvalid;
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: context.colors.error,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthBlocState>(
          listenWhen: (p, n) =>
              p.status != n.status ||
              p.errorMessage != n.errorMessage ||
              p.pendingOtpEmail != n.pendingOtpEmail,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated && mounted) {
              Navigator.of(context).pop();
              return;
            }
            if (state.status == AuthStatus.submitting && !_verifying) {
              // _verifying is managed locally; this branch only handles
              // resend-triggered submitting when local flag is already reset.
            }
            if (state.errorMessage != null) {
              _showError(safeErrorMessage(l10n, state.errorMessage));
            }
            if (state.pendingOtpEmail == widget.email &&
                state.errorMessage == null &&
                state.status != AuthStatus.submitting) {
              _startCooldown();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: context.colors.tertiary,
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.otpResent,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!_verifying) {
              setState(() => _resending = false);
            }
          },
          builder: (context, state) {
            final blocSubmitting = state.status == AuthStatus.submitting;
            final resendLabel = _cooldown > 0
                ? l10n.otpResendIn(_cooldown)
                : l10n.otpResend;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pin_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.otpTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.otpSubtitle(widget.email),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _otp,
                    enabled: !_busy && !blocSubmitting,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    validator: _validateOtp,
                    onFieldSubmitted: (_) => _verify(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_otpLength),
                    ],
                    style: const TextStyle(fontSize: 24, letterSpacing: 4),
                    decoration: InputDecoration(
                      hintText: '00000000',
                      hintStyle: TextStyle(color: context.textSecondary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (_busy || blocSubmitting) ? null : _verify,
                    child: _verifying || (blocSubmitting && _resending == false)
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            l10n.otpVerify,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: (_busy || _cooldown > 0 || blocSubmitting) ? null : _resend,
                    icon: _resending
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(
                      resendLabel,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy || blocSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.otpChangeEmail,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
