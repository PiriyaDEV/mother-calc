class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? promptpay;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final String locale;

  const Profile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.promptpay,
    this.onboardingCompleted = false,
    this.createdAt,
    this.locale = 'th',
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      promptpay: json['promptpay'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      locale: json['locale'] as String? ?? 'th',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'promptpay': promptpay,
        'onboarding_completed': onboardingCompleted,
        'created_at': createdAt?.toIso8601String(),
        'locale': locale,
      };

  Profile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? promptpay,
    bool? onboardingCompleted,
    String? locale,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      promptpay: promptpay ?? this.promptpay,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      locale: locale ?? this.locale,
    );
  }
}
