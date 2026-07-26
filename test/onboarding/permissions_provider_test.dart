import 'package:cricunity/onboarding/permissions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both permissions start undetermined', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(permissionsProvider);

    expect(state.location, PermissionStatus.undetermined);
    expect(state.notifications, PermissionStatus.undetermined);
  });

  test('setLocation and setNotifications are independent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(permissionsProvider.notifier);

    notifier.setLocation(PermissionStatus.granted);
    notifier.setNotifications(PermissionStatus.denied);

    final state = container.read(permissionsProvider);
    expect(state.location, PermissionStatus.granted);
    expect(state.notifications, PermissionStatus.denied);
  });

  test('reset returns to the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(permissionsProvider.notifier);
    notifier.setLocation(PermissionStatus.granted);

    notifier.reset();

    expect(
      container.read(permissionsProvider).location,
      PermissionStatus.undetermined,
    );
  });
}
