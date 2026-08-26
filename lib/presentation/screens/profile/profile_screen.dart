import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../core/di.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/credit_transaction.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/credit_transaction_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/credit_transactions/credit_transactions_bloc.dart';
import '../../blocs/legal_consent/legal_consent_cubit.dart';
import '../../blocs/locale/locale_cubit.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../widgets/ads_banner_widget.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user!.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>(
          create: (_) =>
              ProfileCubit(getIt<ProfileRepository>())..loadProfile(userId),
        ),
        BlocProvider<CreditTransactionsBloc>(
          create: (_) =>
              CreditTransactionsBloc(getIt<CreditTransactionRepository>())
                ..add(CreditTransactionsStarted(userId)),
        ),
      ],
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (p, n) => n is ProfileActionSuccess || n is ProfileError,
        listener: (context, state) {
          if (state is ProfileActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success,
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(state.message),
                  ],
                ),
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.error,
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
              ),
            );
          }
        },
        builder: (context, profileState) {
          if (profileState is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profileState is ProfileError && profileState.profile == null) {
            return Center(child: Text(profileState.message));
          }

          final profile = profileState is ProfileLoaded
              ? profileState.profile
              : profileState is ProfileActionSuccess
              ? profileState.profile
              : null;

          if (profile == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, profile),
                const SizedBox(height: 24),
                _buildEntitlementsSection(context),
                const SizedBox(height: 16),
                const AdsBannerWidget(location: AdBannerLocation.profile),
                const SizedBox(height: 24),
                _buildTransactionsSection(context),
                const SizedBox(height: 24),
                _buildSettingsSection(context, profile),
                const SizedBox(height: 24),
                _buildHelpSection(context),
                const SizedBox(height: 24),
                _buildDangerZone(context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthBloc>().state.user;
    return Center(
      child: Column(
        children: [
          _buildAvatar(context, profile),
          const SizedBox(height: 16),
          Text(
            profile.hasDisplayName ? profile.displayName! : l10n.anonymousUser,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (user?.email != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user!.email!,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _providerLabel(context, profile.provider),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showEditDisplayNameDialog(context, profile),
            child: Text(l10n.editDisplayName),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, dynamic profile) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          backgroundImage: profile.hasAvatar
              ? NetworkImage(
                  '${getIt<SupabaseClient>().storage.from('avatars').getPublicUrl(profile.avatarUrl)}?t=${DateTime.now().millisecondsSinceEpoch}',
                )
              : null,
          child: profile.hasAvatar
              ? null
              : Text(
                  (profile.displayName ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showAvatarPicker(context, profile),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntitlementsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthBloc>().state;
    final subState = context.watch<SubscriptionBloc>().state;
    final walletState = context.watch<WalletBloc>().state;
    final nextGrantText = _nextMonthlyCreditText(
      walletState.wallet?.lastGrantAt,
      subState.subscription?.startedAt,
      walletState.wallet?.updatedAt,
      subState.isPlus,
      l10n,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.subscription,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subState.isPlus ? l10n.plusMember : l10n.freeTier,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (subState.subscription != null)
                        Text(
                          l10n.validUntil(
                            _formatDate(subState.subscription!.expiresAt),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      if (nextGrantText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            nextGrantText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!subState.isPlus && !auth.isGuest)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showComingSoonDialog(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            l10n.upgrade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.credits,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.creditsRemaining(walletState.balance),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.creditHistory,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            BlocBuilder<CreditTransactionsBloc, CreditTransactionsState>(
              builder: (context, state) {
                if (state.status == CreditTransactionsStatus.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (state.status == CreditTransactionsStatus.error) {
                  return Center(
                    child: Text(
                      state.error ?? l10n.failedToLoadTransactions,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildFilterChips(context, state),
                    const SizedBox(height: 12),
                    if (state.transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noTransactionsYet,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      ...state.transactions
                          .take(10)
                          .map((tx) => _buildTransactionTile(context, tx)),
                    if (state.transactions.length > 10)
                      TextButton(
                        onPressed: () {
                          context.read<CreditTransactionsBloc>().add(
                            const CreditTransactionsViewAllRequested(),
                          );
                        },
                        child: Text(l10n.viewAll),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    CreditTransactionsState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: Text(l10n.all),
            selected: state.filter == CreditTransactionsFilter.all,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsFilterChanged(
                  CreditTransactionsFilter.all,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.earnings),
            selected: state.filter == CreditTransactionsFilter.earnings,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsFilterChanged(
                  CreditTransactionsFilter.earnings,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.spent),
            selected: state.filter == CreditTransactionsFilter.spent,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsFilterChanged(
                  CreditTransactionsFilter.spent,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.rewards),
            selected: state.filter == CreditTransactionsFilter.rewards,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsFilterChanged(
                  CreditTransactionsFilter.rewards,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, dynamic tx) {
    final l10n = AppLocalizations.of(context)!;
    final isCredit = tx.amount > 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = isCredit
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        _txTypeLabel(l10n, tx.type),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        _formatDateTime(tx.createdAt),
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      ),
      trailing: Text(
        '${isCredit ? '+' : ''}${tx.amount}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, dynamic profile) {
    final l10n = AppLocalizations.of(context)!;
    final isGoogle = profile.provider == LoginProvider.google;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(l10n.emailMarketing),
            subtitle: Text(l10n.receiveTips),
            trailing: Switch(
              value: profile.emailMarketingOptIn,
              onChanged: (value) {
                context.read<ProfileCubit>().toggleEmailMarketing(
                  userId: context.read<AuthBloc>().state.user!.id,
                  currentOptIn: profile.emailMarketingOptIn,
                );
              },
            ),
          ),
          if (!isGoogle) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changePassword),
              subtitle: Text(l10n.updatePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: Text(
              context.watch<LocaleCubit>().state.locale.languageCode == 'id'
                  ? l10n.bahasaIndonesia
                  : l10n.english,
              style: const TextStyle(color: Colors.black54),
            ),
            onTap: () => _showLanguageSheet(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<LocaleCubit>();
    final current = cubit.state.locale.languageCode;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.transparent),
              title: Text(l10n.english),
              trailing: current == 'en'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                cubit.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.transparent),
              title: Text(l10n.bahasaIndonesia),
              trailing: current == 'id'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                cubit.setLocale(const Locale('id'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.primary),
            title: Text(l10n.howItWorks),
            subtitle: Text(l10n.howItWorksSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(replay: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: AppColors.error.withValues(alpha: 0.05),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.primary),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: AppColors.primary),
            ),
            subtitle: Text(
              l10n.signOutDevice,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: Colors.orange),
            title: Text(
              l10n.withdrawPrivacy,
              style: const TextStyle(color: Colors.orange),
            ),
            subtitle: Text(
              l10n.withdrawPrivacySub,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => _showWithdrawPrivacyDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: Text(
              l10n.deleteAccountSubtitle,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEditDisplayNameDialog(BuildContext context, dynamic profile) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: profile.hasDisplayName ? profile.displayName : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editDisplayName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.editDisplayNameHint),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                context.read<ProfileCubit>().updateDisplayName(
                  userId: context.read<AuthBloc>().state.user!.id,
                  displayName: name,
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, dynamic profile) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    final file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (file == null || !context.mounted) return;

    context.read<ProfileCubit>().updateAvatar(
      userId: context.read<AuthBloc>().state.user!.id,
      file: File(file.path),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.changePassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.currentPassword,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.enterCurrentPassword : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.newPassword),
                validator: (v) =>
                    v == null || v.length < 6 ? l10n.passwordMin : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPassword,
                ),
                validator: (v) =>
                    v != newCtrl.text ? l10n.passwordsDoNotMatch : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              context.read<ProfileCubit>().changePassword(
                currentPassword: currentCtrl.text,
                newPassword: newCtrl.text,
              );
              Navigator.pop(ctx);
            },
            child: Text(l10n.change),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileCubit>().deleteAccount();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showWithdrawPrivacyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthBloc>().state.user!.id;
    final locale = context.read<LocaleCubit>().state.locale.languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.withdrawPrivacy),
        content: Text(l10n.withdrawPrivacyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LegalConsentCubit>().withdrawPrivacy(
                userId: userId,
                locale: locale,
              );
            },
            child: Text(l10n.withdrawPrivacyConfirm),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, size: 48),
        title: Text(l10n.comingSoon),
        content: Text(l10n.comingSoonBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.logout}?'),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  String _providerLabel(BuildContext context, LoginProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    switch (provider) {
      case LoginProvider.email:
        return l10n.emailAccount;
      case LoginProvider.google:
        return l10n.googleAccount;
      case LoginProvider.anonymous:
        return l10n.guestAccount;
      case LoginProvider.other:
        return l10n.externalAccount;
    }
  }

  String _txTypeLabel(AppLocalizations l10n, CreditTxType type) {
    switch (type) {
      case CreditTxType.topup:
        return l10n.creditTopup;
      case CreditTxType.dailyReward:
        return l10n.dailyReward;
      case CreditTxType.generateSticker:
        return l10n.stickerGeneration;
      case CreditTxType.refund:
        return l10n.refund;
      case CreditTxType.subscriptionGrant:
        return l10n.subscriptionGrant;
      case CreditTxType.missionReward:
        return l10n.missionReward;
      case CreditTxType.expired:
        return l10n.expired;
      case CreditTxType.locked:
        return l10n.locked;
      case CreditTxType.surprisePrompt:
        return l10n.surpriseMe;
      case CreditTxType.showcasePurchase:
        return l10n.showcasePurchaseLabel;
      case CreditTxType.showcaseSale:
        return l10n.showcaseSaleLabel;
      case CreditTxType.unknown:
        return l10n.unknown;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String? _nextMonthlyCreditText(
    DateTime? lastGrantAt,
    DateTime? startedAt,
    DateTime? walletUpdatedAt,
    bool isPlus,
    AppLocalizations l10n,
  ) {
    final base = lastGrantAt ?? startedAt ?? walletUpdatedAt;
    if (base == null) return null;

    final now = DateTime.now();
    var nextGrant = _addOneMonth(base.toLocal());
    while (!nextGrant.isAfter(now)) {
      nextGrant = _addOneMonth(nextGrant);
    }

    final amount = isPlus ? 50 : 5;
    return l10n.nextMonthlyCredits(amount, _formatDateTime(nextGrant));
  }

  DateTime _addOneMonth(DateTime value) {
    return DateTime(
      value.year,
      value.month + 1,
      value.day,
      value.hour,
      value.minute,
    );
  }
}
