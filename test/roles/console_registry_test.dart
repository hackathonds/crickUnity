import 'package:cricunity/roles/console_registry.dart';
import 'package:cricunity/roles/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every PRD §3.3 role-gated console is present', () {
    const expectedNames = {
      'Captain Console',
      'Manager / Treasury',
      'Scorer Console',
      'Umpire Console',
      'Coach Console',
      'Ground Console',
      'Academy Console',
      'Organizer Console',
      'Club Console',
      'Sponsor Console',
    };
    final actualNames = consoleRegistry.values.map((c) => c.name).toSet();
    expect(actualNames, expectedNames);
  });

  test('Captain, Vice-Captain, and Team Owner share one console', () {
    expect(
      consoleRegistry[UserRole.captain],
      consoleRegistry[UserRole.viceCaptain],
    );
    expect(
      consoleRegistry[UserRole.captain],
      consoleRegistry[UserRole.teamOwner],
    );
  });

  test(
    'consolesFor de-duplicates shared consoles and is empty for no roles',
    () {
      expect(consolesFor({}), isEmpty);
      expect(consolesFor({UserRole.captain}), hasLength(1));
      expect(
        consolesFor({
          UserRole.captain,
          UserRole.viceCaptain,
          UserRole.teamOwner,
        }),
        hasLength(1),
      );
      expect(consolesFor({UserRole.captain, UserRole.scorer}), hasLength(2));
    },
  );

  test('roles without a console map to nothing', () {
    for (final role in [
      UserRole.player,
      UserRole.fan,
      UserRole.admin,
      UserRole.superAdmin,
    ]) {
      expect(consoleRegistry.containsKey(role), isFalse);
    }
  });
}
