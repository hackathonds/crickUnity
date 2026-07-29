import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';

/// E1-03 · DS §11.3 Permissions primer: "one card per permission
/// (location/notifications) with concrete benefit copy and [Allow]/
/// [Later]; denial writes the §6 fallback states."
///
/// No `permission_handler` (or similar) package exists in this repo, so
/// there's no real OS permission dialog to trigger -- [PermissionsNotifier]
/// stands in for that outcome directly. "Later" is treated as a decision
/// (denied) for this session, not a deferred re-ask, since neither PRD nor
/// DS describes a re-prompt schedule.
enum PermissionStatus { undetermined, granted, denied }

class PermissionsState {
  final PermissionStatus location;
  final PermissionStatus notifications;

  const PermissionsState({
    this.location = PermissionStatus.undetermined,
    this.notifications = PermissionStatus.undetermined,
  });

  PermissionsState copyWith({
    PermissionStatus? location,
    PermissionStatus? notifications,
  }) {
    return PermissionsState(
      location: location ?? this.location,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'location': location.name,
    'notifications': notifications.name,
  };

  factory PermissionsState.fromJson(Map<String, dynamic> json) {
    return PermissionsState(
      location: PermissionStatus.values.byName(json['location'] as String),
      notifications: PermissionStatus.values.byName(
        json['notifications'] as String,
      ),
    );
  }
}

class PermissionsNotifier extends PersistedNotifier<PermissionsState> {
  @override
  String get persistenceKey => 'permissions_v1';

  @override
  PermissionsState seed() => const PermissionsState();

  @override
  Map<String, dynamic> toJson(PermissionsState value) => value.toJson();

  @override
  PermissionsState fromJson(Map<String, dynamic> json) =>
      PermissionsState.fromJson(json);

  void setLocation(PermissionStatus status) =>
      state = state.copyWith(location: status);

  void setNotifications(PermissionStatus status) =>
      state = state.copyWith(notifications: status);

  void reset() => state = const PermissionsState();
}

final permissionsProvider =
    NotifierProvider<PermissionsNotifier, PermissionsState>(
      PermissionsNotifier.new,
    );
