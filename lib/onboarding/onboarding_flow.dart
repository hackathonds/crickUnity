import 'package:flutter/material.dart';

import 'city_step_screen.dart';
import 'dob_step_screen.dart';
import 'guardian_contact_screen.dart';
import 'guardian_explainer_screen.dart';
import 'guardian_waiting_screen.dart';
import 'name_entry_screen.dart';
import 'otp_screen.dart';
import 'permissions_primer_screen.dart';
import 'phone_entry_screen.dart';
import 'photo_step_screen.dart';
import 'playing_info_step_screen.dart';
import 'registration_complete_screen.dart';
import 'warm_up_screen.dart';
import 'welcome_screen.dart';

/// Chains E1-01 + E1-02 + E1-03's screens together via plain Navigator
/// pushes. [onExploreAsGuest] is exposed since Guest mode (E1-04) still
/// doesn't exist -- the main "Get started" path no longer needs it (it
/// now runs all the way to [onOnboardingComplete] on its own), but
/// Welcome's "Explore first" button does.
class OnboardingFlow extends StatelessWidget {
  final VoidCallback onExploreAsGuest;
  final VoidCallback onContactSupport;
  final VoidCallback onOnboardingComplete;

  /// QA-only: see [GuardianWaitingScreen.showDebugSimulateApproval].
  final bool showDebugSimulateApproval;

  const OnboardingFlow({
    super.key,
    required this.onExploreAsGuest,
    required this.onContactSupport,
    required this.onOnboardingComplete,
    this.showDebugSimulateApproval = false,
  });

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onGetStarted: () => _pushPhoneEntry(context),
      onExploreAsGuest: onExploreAsGuest,
    );
  }

  void _pushPhoneEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) =>
            PhoneEntryScreen(onContinue: (_) => _pushOtp(pageContext)),
      ),
    );
  }

  void _pushOtp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => OtpScreen(
          onContactSupport: onContactSupport,
          onVerified: (isExistingAccount) {
            if (isExistingAccount) {
              _pushWelcomeBack(pageContext);
            } else {
              _pushNameEntry(pageContext);
            }
          },
        ),
      ),
    );
  }

  void _pushWelcomeBack(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) =>
            RegistrationCompleteScreen(onDone: onOnboardingComplete),
      ),
    );
  }

  void _pushNameEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) =>
            NameEntryScreen(onContinue: (_) => _pushDobStep(pageContext)),
      ),
    );
  }

  void _pushDobStep(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => DobStepScreen(
          onContinue: (isMinor) {
            if (isMinor) {
              _pushGuardianExplainer(pageContext);
            } else {
              _pushPhotoStep(pageContext);
            }
          },
        ),
      ),
    );
  }

  void _pushGuardianExplainer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => GuardianExplainerScreen(
          onContinue: () => _pushGuardianContact(pageContext),
        ),
      ),
    );
  }

  void _pushGuardianContact(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => GuardianContactScreen(
          onSent: () => _pushGuardianWaiting(pageContext),
        ),
      ),
    );
  }

  void _pushGuardianWaiting(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => GuardianWaitingScreen(
          showDebugSimulateApproval: showDebugSimulateApproval,
          onConsentGranted: () => _pushPhotoStep(pageContext),
        ),
      ),
    );
  }

  void _pushPhotoStep(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) =>
            PhotoStepScreen(onContinue: () => _pushCityStep(pageContext)),
      ),
    );
  }

  void _pushCityStep(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) =>
            CityStepScreen(onContinue: () => _pushPlayingInfoStep(pageContext)),
      ),
    );
  }

  void _pushPlayingInfoStep(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => PlayingInfoStepScreen(
          onContinue: () => _pushPermissionsPrimer(pageContext),
        ),
      ),
    );
  }

  void _pushPermissionsPrimer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) =>
            PermissionsPrimerScreen(onContinue: () => _pushWarmUp(pageContext)),
      ),
    );
  }

  void _pushWarmUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => WarmUpScreen(onDone: onOnboardingComplete),
      ),
    );
  }
}
