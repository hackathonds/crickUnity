import 'package:flutter_riverpod/flutter_riverpod.dart';

/// E1-01 · DS §11.3 Registration: "single-field-per-screen rhythm (phone →
/// OTP 6-cell auto-advance boxes 48, resend countdown 30s, 3 attempts →
/// cooldown state with support link → name)."
///
/// No backend/auth system exists in this repo yet, so OTP verification and
/// "existing account" detection are mocked:
/// - [demoCorrectOtp] is the one code that always verifies (shown as a hint
///   on the OTP screen, not hidden -- there's nothing to protect yet).
/// - [existingAccountPhones] is a small hardcoded set standing in for a
///   real accounts lookup, so PRD §20-A2's "existing account -> login
///   suggest" edge case is demonstrable.
const String demoCorrectOtp = '000000';
const Set<String> existingAccountPhones = {'9999999999', '8888888888'};

const int maxOtpAttempts = 3;
const Duration otpResendCooldown = Duration(seconds: 30);

enum OtpSubmitResult { correct, incorrect, cooldown }

class RegistrationState {
  final String phone;

  /// Null until a code has been (re)sent; drives the 30s resend countdown.
  final DateTime? codeSentAt;
  final int attemptsUsed;
  final bool otpVerified;

  /// Only meaningful once [otpVerified] is true. PRD §20-A2: an existing
  /// account skips the name step and goes straight to a "welcome back"
  /// completion -- this app has no separate password-login screen, so OTP
  /// verification doubles as the sign-in mechanism for a returning user.
  final bool isExistingAccount;
  final String name;

  const RegistrationState({
    this.phone = '',
    this.codeSentAt,
    this.attemptsUsed = 0,
    this.otpVerified = false,
    this.isExistingAccount = false,
    this.name = '',
  });

  bool get inCooldown => attemptsUsed >= maxOtpAttempts;

  RegistrationState copyWith({
    String? phone,
    DateTime? codeSentAt,
    int? attemptsUsed,
    bool? otpVerified,
    bool? isExistingAccount,
    String? name,
  }) {
    return RegistrationState(
      phone: phone ?? this.phone,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      otpVerified: otpVerified ?? this.otpVerified,
      isExistingAccount: isExistingAccount ?? this.isExistingAccount,
      name: name ?? this.name,
    );
  }
}

class RegistrationFlowNotifier extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  /// Phone step -> sends the (mock) first code, starting a fresh 3-attempt
  /// budget for this number.
  void submitPhone(String phone) {
    state = RegistrationState(phone: phone, codeSentAt: DateTime.now());
  }

  /// Resending is the only recovery path out of a cooldown (DS says
  /// "cooldown state with support link" but gives no unlock duration --
  /// support is a human-in-the-loop escape hatch, a fresh code is the
  /// self-service one, reusing the already-specified resend affordance
  /// rather than inventing a new timer value).
  void resendCode() {
    state = state.copyWith(codeSentAt: DateTime.now(), attemptsUsed: 0);
  }

  OtpSubmitResult submitOtp(String code) {
    if (state.inCooldown) return OtpSubmitResult.cooldown;

    if (code == demoCorrectOtp) {
      state = state.copyWith(
        otpVerified: true,
        isExistingAccount: existingAccountPhones.contains(state.phone),
      );
      return OtpSubmitResult.correct;
    }

    final attempts = state.attemptsUsed + 1;
    state = state.copyWith(attemptsUsed: attempts);
    return attempts >= maxOtpAttempts
        ? OtpSubmitResult.cooldown
        : OtpSubmitResult.incorrect;
  }

  void setName(String name) => state = state.copyWith(name: name);

  void reset() => state = const RegistrationState();
}

final registrationFlowProvider =
    NotifierProvider<RegistrationFlowNotifier, RegistrationState>(
      RegistrationFlowNotifier.new,
    );
