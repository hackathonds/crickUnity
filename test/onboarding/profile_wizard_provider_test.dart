import 'package:cricunity/onboarding/profile_wizard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at 0% completeness with everything unset', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(profileWizardProvider);

    expect(state.completeness, 0.0);
  });

  test('completeness rises by a quarter per field filled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(profileWizardProvider.notifier);

    notifier.setPhotoSet(true);
    expect(container.read(profileWizardProvider).completeness, 0.25);

    notifier.setCity('Mumbai');
    expect(container.read(profileWizardProvider).completeness, 0.5);

    notifier.setPrimaryRole(PrimaryRole.batter);
    expect(container.read(profileWizardProvider).completeness, 0.75);

    notifier.setBattingStyle(BattingStyle.rhb);
    expect(container.read(profileWizardProvider).completeness, 1.0);
  });

  test('setting a field to null lowers completeness back down', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(profileWizardProvider.notifier);
    notifier.setCity('Mumbai');

    notifier.setCity(null);

    expect(container.read(profileWizardProvider).city, isNull);
    expect(container.read(profileWizardProvider).completeness, 0.0);
  });

  test('reset returns to the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(profileWizardProvider.notifier);
    notifier.setPhotoSet(true);
    notifier.setCity('Mumbai');

    notifier.reset();

    final state = container.read(profileWizardProvider);
    expect(state.photoSet, isFalse);
    expect(state.city, isNull);
    expect(state.completeness, 0.0);
  });
}
