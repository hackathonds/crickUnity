import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_role.dart';

/// PRD §3.1/§3.6: "Long-press Profile → account switcher (multi-role
/// identities, e.g., 'Deepak – Scorer view')." A viewing lens over
/// roles the account already holds ([currentRolesProvider]) -- never
/// a role picker (non-negotiable #10). Null means the default
/// self/Player view.
class ActiveRoleViewNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;

  void setView(UserRole? role) => state = role;
}

final activeRoleViewProvider =
    NotifierProvider<ActiveRoleViewNotifier, UserRole?>(
      ActiveRoleViewNotifier.new,
    );

/// PRD §3.1: "Ground Owners see Bookings replacing Community if they
/// enable 'Business mode' toggle." Only meaningful when the account
/// actually holds [UserRole.groundOwner] -- the toggle itself doesn't
/// grant the role (non-negotiable #10).
class BusinessModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final businessModeProvider = NotifierProvider<BusinessModeNotifier, bool>(
  BusinessModeNotifier.new,
);
