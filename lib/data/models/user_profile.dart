import 'package:equatable/equatable.dart';

enum LoginProvider { email, google, anonymous, other }

LoginProvider _providerFrom(String? raw) {
  switch (raw) {
    case 'email':
      return LoginProvider.email;
    case 'google':
      return LoginProvider.google;
    case 'anonymous':
      return LoginProvider.anonymous;
    default:
      return LoginProvider.other;
  }
}

class UserProfile extends Equatable {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final LoginProvider provider;
  final bool emailMarketingOptIn;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.provider,
    required this.emailMarketingOptIn,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasDisplayName =>
      displayName != null && displayName!.trim().isNotEmpty;
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      provider: _providerFrom(json['provider'] as String?),
      emailMarketingOptIn: json['email_marketing_opt_in'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    LoginProvider? provider,
    bool? emailMarketingOptIn,
    bool? isDeleted,
  }) {
    return UserProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      emailMarketingOptIn: emailMarketingOptIn ?? this.emailMarketingOptIn,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    displayName,
    avatarUrl,
    provider,
    emailMarketingOptIn,
    isDeleted,
    createdAt,
    updatedAt,
  ];
}
