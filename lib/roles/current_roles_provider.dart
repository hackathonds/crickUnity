import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'user_role.dart';

/// The set of roles this account currently holds. Starts empty — PRD:
/// real accounts default to Fan/Player via onboarding (E1), but nothing
/// here activates a console until real activity earns it (non-negotiable
/// #10). The debug shell screen is the only place that mutates this
/// directly, simulating "activity just granted this role."
class CurrentRolesNotifier extends PersistedNotifier<Set<UserRole>> {
  @override
  String get persistenceKey => 'current_roles_v1';

  @override
  Set<UserRole> seed() => <UserRole>{};

  @override
  Map<String, dynamic> toJson(Set<UserRole> value) => {
    'roles': [for (final r in value) r.name],
  };

  @override
  Set<UserRole> fromJson(Map<String, dynamic> json) => {
    for (final r in json['roles'] as List) UserRole.values.byName(r as String),
  };

  void activate(UserRole role) => state = {...state, role};

  void deactivate(UserRole role) => state = {...state}..remove(role);

  void toggle(UserRole role) {
    if (state.contains(role)) {
      deactivate(role);
    } else {
      activate(role);
    }
  }
}

final currentRolesProvider =
    NotifierProvider<CurrentRolesNotifier, Set<UserRole>>(
      CurrentRolesNotifier.new,
    );
