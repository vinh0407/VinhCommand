import 'package:equatable/equatable.dart';

enum OnlineAccountProvider {
  chatgptWeb,
  geminiWeb,
  openaiOnline,
}

enum AccountStatus {
  active,
  needLogin,
  expired,
}

class OnlineAccount extends Equatable {
  final String id;
  final OnlineAccountProvider provider;
  final String name; // e.g. email or username
  final AccountStatus status;
  final String? sessionToken;
  final String modelPlan; // e.g. Free, Plus, Pro, Gemini Advanced
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final Map<String, dynamic> metadata;

  const OnlineAccount({
    required this.id,
    required this.provider,
    required this.name,
    required this.status,
    this.sessionToken,
    this.modelPlan = 'Free',
    this.isDefault = false,
    required this.createdAt,
    this.lastUsedAt,
    this.metadata = const {},
  });

  OnlineAccount copyWith({
    String? id,
    OnlineAccountProvider? provider,
    String? name,
    AccountStatus? status,
    String? sessionToken,
    String? modelPlan,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Map<String, dynamic>? metadata,
  }) {
    return OnlineAccount(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      name: name ?? this.name,
      status: status ?? this.status,
      sessionToken: sessionToken ?? this.sessionToken,
      modelPlan: modelPlan ?? this.modelPlan,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.name,
      'name': name,
      'status': status.name,
      'sessionToken': sessionToken,
      'modelPlan': modelPlan,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory OnlineAccount.fromJson(Map<String, dynamic> json) {
    return OnlineAccount(
      id: json['id'] as String,
      provider: OnlineAccountProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => OnlineAccountProvider.chatgptWeb,
      ),
      name: json['name'] as String? ?? 'Account',
      status: AccountStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AccountStatus.active,
      ),
      sessionToken: json['sessionToken'] as String?,
      modelPlan: json['modelPlan'] as String? ?? 'Free',
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  @override
  List<Object?> get props => [
        id,
        provider,
        name,
        status,
        sessionToken,
        modelPlan,
        isDefault,
        createdAt,
        lastUsedAt,
        metadata,
      ];
}
