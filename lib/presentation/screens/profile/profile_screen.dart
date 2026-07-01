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
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/credit_transactions/credit_transactions_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                const SizedBox(height: 24),
                _buildTransactionsSection(context),
                const SizedBox(height: 24),
                _buildSettingsSection(context, profile),
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
    return Center(
      child: Column(
        children: [
          _buildAvatar(context, profile),
          const SizedBox(height: 16),
          Text(
            profile.hasDisplayName ? profile.displayName! : 'Anonymous User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _providerLabel(profile.provider),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showEditDisplayNameDialog(context, profile),
            child: const Text('Edit display name'),
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
    final auth = context.watch<AuthBloc>().state;
    final subState = context.watch<SubscriptionBloc>().state;
    final walletState = context.watch<WalletBloc>().state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subState.isPlus ? 'Plus Member' : 'Free Tier',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (subState.subscription != null)
                      Text(
                        'Valid until ${_formatDate(subState.subscription!.expiresAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            'Upgrade',
                            style: TextStyle(
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
                    const Text(
                      'Credits',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${walletState.balance} remaining',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Credit History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      state.error ?? 'Failed to load transactions',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (state.transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildFilterChips(context, state),
                    const SizedBox(height: 12),
                    ...state.transactions
                        .take(10)
                        .map((tx) => _buildTransactionTile(tx)),
                    if (state.transactions.length > 10)
                      TextButton(
                        onPressed: () {},
                        child: const Text('View all'),
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
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.filterType == null,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsTypeFilterChanged(null),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Earnings'),
            selected: state.filterType == CreditTxType.dailyReward,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsTypeFilterChanged(
                  CreditTxType.dailyReward,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Spent'),
            selected: state.filterType == CreditTxType.generateSticker,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsTypeFilterChanged(
                  CreditTxType.generateSticker,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Rewards'),
            selected: state.filterType == CreditTxType.missionReward,
            onSelected: (_) {
              context.read<CreditTransactionsBloc>().add(
                const CreditTransactionsTypeFilterChanged(
                  CreditTxType.missionReward,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(dynamic tx) {
    final isCredit = tx.amount > 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = isCredit
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(_txTypeLabel(tx.type), style: const TextStyle(fontSize: 14)),
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
    final isGoogle = profile.provider == LoginProvider.google;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email Marketing'),
            subtitle: const Text('Receive tips and promotions'),
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
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.05),
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: AppColors.error),
        title: Text('Delete Account', style: TextStyle(color: AppColors.error)),
        subtitle: const Text(
          'Permanently delete your account and data',
          style: TextStyle(fontSize: 12),
        ),
        onTap: () => _showDeleteAccountDialog(context),
      ),
    );
  }

  void _showEditDisplayNameDialog(BuildContext context, dynamic profile) {
    final ctrl = TextEditingController(
      text: profile.hasDisplayName ? profile.displayName : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, dynamic profile) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
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
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                validator: (v) =>
                    v != newCtrl.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. Your account and all data will be '
          'permanently deleted after 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileCubit>().deleteAccount();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, size: 48),
        title: const Text('Coming Soon'),
        content: const Text(
          'Plus subscription upgrade will be available soon!',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _providerLabel(LoginProvider provider) {
    switch (provider) {
      case LoginProvider.email:
        return 'Email Account';
      case LoginProvider.google:
        return 'Google Account';
      case LoginProvider.anonymous:
        return 'Guest Account';
      case LoginProvider.other:
        return 'External Account';
    }
  }

  String _txTypeLabel(CreditTxType type) {
    switch (type) {
      case CreditTxType.topup:
        return 'Credit Top-up';
      case CreditTxType.dailyReward:
        return 'Daily Reward';
      case CreditTxType.generateSticker:
        return 'Sticker Generation';
      case CreditTxType.refund:
        return 'Refund';
      case CreditTxType.subscriptionGrant:
        return 'Subscription Grant';
      case CreditTxType.missionReward:
        return 'Mission Reward';
      case CreditTxType.expired:
        return 'Expired';
      case CreditTxType.locked:
        return 'Locked';
      case CreditTxType.adminGrant:
        return 'Admin Grant';
      case CreditTxType.unknown:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
