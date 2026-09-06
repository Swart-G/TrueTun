import 'package:truetun/src/profiles/proxy_node.dart';

class ManagedProfile {
  const ManagedProfile({required this.id, required this.node});

  final String id;
  final VlessNode node;

  ManagedProfile copyWith({String? id, VlessNode? node}) {
    return ManagedProfile(
      id: id ?? this.id,
      node: node ?? this.node,
    );
  }
}

class ProfileGroup {
  const ProfileGroup({
    required this.id,
    required this.name,
    this.subscriptionUrl,
    this.autoUpdateEnabled = false,
    this.autoUpdateMinutes = 60,
    this.profiles = const [],
    this.updating = false,
    this.error,
  });

  final String id;
  final String name;
  final Uri? subscriptionUrl;
  final bool autoUpdateEnabled;
  final int autoUpdateMinutes;
  final List<ManagedProfile> profiles;
  final bool updating;
  final String? error;

  bool get isSubscription => subscriptionUrl != null;

  ProfileGroup copyWith({
    String? id,
    String? name,
    Uri? subscriptionUrl,
    bool clearSubscriptionUrl = false,
    bool? autoUpdateEnabled,
    int? autoUpdateMinutes,
    List<ManagedProfile>? profiles,
    bool? updating,
    String? error,
    bool clearError = false,
  }) {
    return ProfileGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      subscriptionUrl:
          clearSubscriptionUrl ? null : subscriptionUrl ?? this.subscriptionUrl,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      autoUpdateMinutes: autoUpdateMinutes ?? this.autoUpdateMinutes,
      profiles: profiles ?? this.profiles,
      updating: updating ?? this.updating,
      error: clearError ? null : error ?? this.error,
    );
  }
}
