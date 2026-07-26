import 'package:flutter_riverpod/flutter_riverpod.dart';

/// E1-02 · DS §11.3 Guardian gate: "DOB step detects minor -> explains
/// guardian requirement plainly -> guardian contact capture -> 'waiting'
/// state screen with resend; app unusable past this point until consent
/// (business rule §17)."
///
/// Neither PRD §17 nor DS ever states a numeric age-of-majority cutoff --
/// 18 is the standard real-world meaning of "minor" this app's own
/// guardian-consent framing implies (full parental consent, not a
/// lighter-touch age-gate), used here as an assumption rather than a
/// literal citation.
const int ageOfMajority = 18;

bool computeIsMinor(DateTime dateOfBirth, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  var age = reference.year - dateOfBirth.year;
  final hadBirthdayThisYear =
      reference.month > dateOfBirth.month ||
      (reference.month == dateOfBirth.month &&
          reference.day >= dateOfBirth.day);
  if (!hadBirthdayThisYear) age -= 1;
  return age < ageOfMajority;
}

/// PRD §5.20 "Private+": Private preset plus no public messaging plus
/// guardian co-notification on new follower requests. No Profile/Privacy
/// screen exists yet to enforce this against -- this is the data flag
/// those later stories will read.
class MinorPrivacyDefaults {
  final bool isPrivate;
  final bool publicMessagingAllowed;
  final bool guardianCoNotificationEnabled;

  const MinorPrivacyDefaults({
    this.isPrivate = true,
    this.publicMessagingAllowed = false,
    this.guardianCoNotificationEnabled = true,
  });
}

class GuardianGateState {
  final DateTime? dateOfBirth;
  final bool? isMinor;
  final String guardianPhone;

  /// Null until a consent request has been (re)sent; drives the resend
  /// countdown. DS gives no duration for this resend (unlike OTP's
  /// explicit 30s) -- [guardianResendCooldown] reuses that same 30s
  /// convention rather than inventing a new value.
  final DateTime? consentRequestSentAt;
  final bool consentGranted;
  final MinorPrivacyDefaults? appliedDefaults;

  const GuardianGateState({
    this.dateOfBirth,
    this.isMinor,
    this.guardianPhone = '',
    this.consentRequestSentAt,
    this.consentGranted = false,
    this.appliedDefaults,
  });

  GuardianGateState copyWith({
    DateTime? dateOfBirth,
    bool? isMinor,
    String? guardianPhone,
    DateTime? consentRequestSentAt,
    bool? consentGranted,
    MinorPrivacyDefaults? appliedDefaults,
  }) {
    return GuardianGateState(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isMinor: isMinor ?? this.isMinor,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      consentRequestSentAt: consentRequestSentAt ?? this.consentRequestSentAt,
      consentGranted: consentGranted ?? this.consentGranted,
      appliedDefaults: appliedDefaults ?? this.appliedDefaults,
    );
  }
}

const Duration guardianResendCooldown = Duration(seconds: 30);

class GuardianGateNotifier extends Notifier<GuardianGateState> {
  @override
  GuardianGateState build() => const GuardianGateState();

  bool submitDateOfBirth(DateTime dateOfBirth) {
    final minor = computeIsMinor(dateOfBirth);
    state = state.copyWith(dateOfBirth: dateOfBirth, isMinor: minor);
    return minor;
  }

  void sendGuardianRequest(String phone) {
    state = state.copyWith(
      guardianPhone: phone,
      consentRequestSentAt: DateTime.now(),
    );
  }

  void resendGuardianRequest() {
    state = state.copyWith(consentRequestSentAt: DateTime.now());
  }

  /// No backend exists to receive a real guardian approval (that would
  /// arrive from the guardian's own device) -- this stands in for that
  /// event, exposed for a debug-only "simulate approval" affordance rather
  /// than any button the real screen renders.
  void grantConsent() {
    state = state.copyWith(
      consentGranted: true,
      appliedDefaults: const MinorPrivacyDefaults(),
    );
  }

  void reset() => state = const GuardianGateState();
}

final guardianGateProvider =
    NotifierProvider<GuardianGateNotifier, GuardianGateState>(
      GuardianGateNotifier.new,
    );
