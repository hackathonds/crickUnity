import 'package:cricunity/onboarding/registration_flow_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submitPhone stores the phone and starts a fresh attempt budget', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);

    notifier.submitPhone('7000000000');

    final state = container.read(registrationFlowProvider);
    expect(state.phone, '7000000000');
    expect(state.codeSentAt, isNotNull);
    expect(state.attemptsUsed, 0);
  });

  test('submitOtp with the demo code verifies a fresh number as new', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone('7000000000');

    final result = notifier.submitOtp(demoCorrectOtp);

    expect(result, OtpSubmitResult.correct);
    final state = container.read(registrationFlowProvider);
    expect(state.otpVerified, isTrue);
    expect(state.isExistingAccount, isFalse);
  });

  test('submitOtp recognizes a mocked existing-account phone', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone(existingAccountPhones.first);

    notifier.submitOtp(demoCorrectOtp);

    expect(container.read(registrationFlowProvider).isExistingAccount, isTrue);
  });

  test('an incorrect code increments attempts without verifying', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone('7000000000');

    final result = notifier.submitOtp('111111');

    expect(result, OtpSubmitResult.incorrect);
    final state = container.read(registrationFlowProvider);
    expect(state.attemptsUsed, 1);
    expect(state.otpVerified, isFalse);
  });

  test('the 3rd incorrect attempt enters cooldown', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone('7000000000');

    notifier.submitOtp('111111');
    notifier.submitOtp('111111');
    final third = notifier.submitOtp('111111');

    expect(third, OtpSubmitResult.cooldown);
    expect(container.read(registrationFlowProvider).inCooldown, isTrue);
  });

  test('submitOtp while already in cooldown returns cooldown without '
      'consuming another attempt', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone('7000000000');
    notifier.submitOtp('111111');
    notifier.submitOtp('111111');
    notifier.submitOtp('111111');

    final result = notifier.submitOtp(demoCorrectOtp);

    expect(result, OtpSubmitResult.cooldown);
    expect(container.read(registrationFlowProvider).attemptsUsed, 3);
  });

  test('resendCode resets attempts and exits cooldown', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone('7000000000');
    notifier.submitOtp('111111');
    notifier.submitOtp('111111');
    notifier.submitOtp('111111');
    expect(container.read(registrationFlowProvider).inCooldown, isTrue);

    notifier.resendCode();

    final state = container.read(registrationFlowProvider);
    expect(state.inCooldown, isFalse);
    expect(state.attemptsUsed, 0);
  });

  test('setName stores the trimmed-by-caller name', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);

    notifier.setName('Priya Nair');

    expect(container.read(registrationFlowProvider).name, 'Priya Nair');
  });

  test('reset returns to the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(registrationFlowProvider.notifier);
    notifier.submitPhone('7000000000');
    notifier.setName('Priya Nair');

    notifier.reset();

    final state = container.read(registrationFlowProvider);
    expect(state.phone, '');
    expect(state.name, '');
    expect(state.codeSentAt, isNull);
  });
}
