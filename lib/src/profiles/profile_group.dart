import 'package:truetun/src/profiles/proxy_node.dart';

class ManagedProfile {
  const ManagedProfile({required this.id, required this.node});

  final String id;
  final VlessNode node;
}

class ProfileGroup {
  const ProfileGroup({
    required this.id,
    required this.name,
    this.subscriptionUrl,
    this.profiles = const [],
    this.updatedAt,
    this.updating = false,
    this.error,
    this.autoUpdateEnabled = false,
    this.autoUpdateMinutes = 60,
  });

  final String id;
  final String name;
  final Uri? subscriptionUrl;
  final List<ManagedProfile> profiles;
  final DateTime? updatedAt;
  final bool updating;
  final String? error;
  final bool autoUpdateEnabled;
  final int autoUpdateMinutes;

  bool get isSubscription => subscriptionUrl != null;

  ProfileGroup copyWith({
    String? name,
    List<ManagedProfile>? profiles,
    DateTime? updatedAt,
    bool? updating,
    String? error,
    bool clearError = false,
    Uri? subscriptionUrl,
    bool clearSubscriptionUrl = false,
    bool? autoUpdateEnabled,
    int? autoUpdateMinutes,
  }) {
    return ProfileGroup(
      id: id,
      name: name ?? this.name,
      subscriptionUrl:
          clearSubscriptionUrl ? null : subscriptionUrl ?? this.subscriptionUrl,
      profiles: profiles ?? this.profiles,
      updatedAt: updatedAt ?? this.updatedAt,
      updating: updating ?? this.updating,
      error: clearError ? null : error ?? this.error,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      autoUpdateMinutes: autoUpdateMinutes ?? this.autoUpdateMinutes,
    );
  }
}
