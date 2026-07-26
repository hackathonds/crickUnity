import 'package:cricunity/onboarding/guardian_gate_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeIsMinor', () {
    test('is true the day before an 18th birthday', () {
      final now = DateTime(2026, 6, 15);
      final dob = DateTime(2008, 6, 16);
      expect(computeIsMinor(dob, now: now), isTrue);
    });

    test('is false on the 18th birthday itself', () {
      final now = DateTime(2026, 6, 15);
      final dob = DateTime(2008, 6, 15);
      expect(computeIsMinor(dob, now: now), isFalse);
    });

    test('is false the day after turning 18', () {
      final now = DateTime(2026, 6, 15);
      final dob = DateTime(2008, 6, 14);
      expect(computeIsMinor(dob, now: now), isFalse);
    });

    test('is true for a young child', () {
      final now = DateTime(2026, 6, 15);
      final dob = DateTime(2018, 1, 1);
      expect(computeIsMinor(dob, now: now), isTrue);
    });
  });

  test('submitDateOfBirth stores the DOB and returns/records isMinor', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guardianGateProvider.notifier);

    final result = notifier.submitDateOfBirth(DateTime(2018, 1, 1));

    expect(result, isTrue);
    final state = container.read(guardianGateProvider);
    expect(state.isMinor, isTrue);
    expect(state.dateOfBirth, DateTime(2018, 1, 1));
  });

  test('sendGuardianRequest stores the phone and a send timestamp', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guardianGateProvider.notifier);

    notifier.sendGuardianRequest('9000000000');

    final state = container.read(guardianGateProvider);
    expect(state.guardianPhone, '9000000000');
    expect(state.consentRequestSentAt, isNotNull);
  });

  test('resendGuardianRequest refreshes the send timestamp', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guardianGateProvider.notifier);
    notifier.sendGuardianRequest('9000000000');
    final firstSentAt = container
        .read(guardianGateProvider)
        .consentRequestSentAt;

    await Future<void>.delayed(const Duration(milliseconds: 5));
    notifier.resendGuardianRequest();

    final secondSentAt = container
        .read(guardianGateProvider)
        .consentRequestSentAt;
    expect(secondSentAt!.isAfter(firstSentAt!), isTrue);
  });

  test('grantConsent sets consentGranted and applies Private+ defaults', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guardianGateProvider.notifier);

    notifier.grantConsent();

    final state = container.read(guardianGateProvider);
    expect(state.consentGranted, isTrue);
    expect(state.appliedDefaults, isNotNull);
    expect(state.appliedDefaults!.isPrivate, isTrue);
    expect(state.appliedDefaults!.publicMessagingAllowed, isFalse);
    expect(state.appliedDefaults!.guardianCoNotificationEnabled, isTrue);
  });

  test('reset returns to the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(guardianGateProvider.notifier);
    notifier.submitDateOfBirth(DateTime(2018, 1, 1));
    notifier.sendGuardianRequest('9000000000');
    notifier.grantConsent();

    notifier.reset();

    final state = container.read(guardianGateProvider);
    expect(state.dateOfBirth, isNull);
    expect(state.isMinor, isNull);
    expect(state.guardianPhone, '');
    expect(state.consentGranted, isFalse);
    expect(state.appliedDefaults, isNull);
  });
}
