import 'package:flutter/material.dart';

import 'name_entry_screen.dart';
import 'otp_screen.dart';
import 'phone_entry_screen.dart';
import 'registration_complete_screen.dart';
import 'welcome_screen.dart';

/// Chains E1-01's screens together via plain Navigator pushes. Not wired
/// into go_router as the app's real entry point yet -- Guardian gate
/// (E1-02), Profile wizard (E1-03), and Guest mode (E1-04) need to exist
/// first, or completing this flow would dead-end (see the story's PR
/// notes). [onExploreAsGuest]/[onContactSupport] are exposed so the caller
/// can wire those once they exist; today's caller (the debug menu) stubs
/// them.
class OnboardingFlow extends StatelessWidget {
  final VoidCallback onExploreAsGuest;
  final VoidCallback onContactSupport;

  const OnboardingFlow({
    super.key,
    required this.onExploreAsGuest,
    required this.onContactSupport,
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
              _pushComplete(pageContext, isExistingAccount: true, name: null);
            } else {
              _pushNameEntry(pageContext);
            }
          },
        ),
      ),
    );
  }

  void _pushNameEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => NameEntryScreen(
          onContinue: (name) =>
              _pushComplete(pageContext, isExistingAccount: false, name: name),
        ),
      ),
    );
  }

  void _pushComplete(
    BuildContext context, {
    required bool isExistingAccount,
    required String? name,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => RegistrationCompleteScreen(
          isExistingAccount: isExistingAccount,
          name: name,
          onDone: () =>
              Navigator.of(pageContext).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }
}
