import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_role.dart';

/// The set of roles this account currently holds. Starts empty — PRD:
/// real accounts default to Fan/Player via onboarding (E1), but nothing
/// here activates a console until real activity earns it (non-negotiable
/// #10). The debug shell screen is the only place that mutates this
/// directly, simulating "activity just granted this role."
class CurrentRolesNotifier extends Notifier<Set<UserRole>> {
  @override
  Set<UserRole> build() => <UserRole>{};

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
