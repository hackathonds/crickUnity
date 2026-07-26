import 'package:flutter/material.dart';

import 'team_city_ground_step_screen.dart';
import 'team_colors_step_screen.dart';
import 'team_created_screen.dart';
import 'team_format_step_screen.dart';
import 'team_join_policy_step_screen.dart';
import 'team_logo_step_screen.dart';
import 'team_models.dart';
import 'team_name_step_screen.dart';

/// PRD §6.1's create-team wizard, chained via plain Navigator pushes --
/// same pattern as `onboarding_flow.dart`. Unlike onboarding (rendered as
/// the app's root content, no popping needed), this flow is expected to
/// be *pushed* onto an existing stack (e.g. from "My Teams"), so
/// completing it needs to pop back past every step it pushed -- tracked
/// via the route that was active when the flow started.
class CreateTeamFlow extends StatelessWidget {
  final ValueChanged<Team> onTeamCreated;

  const CreateTeamFlow({super.key, required this.onTeamCreated});

  @override
  Widget build(BuildContext context) {
    final entryRoute = ModalRoute.of(context);
    return TeamNameStepScreen(onContinue: () => _pushLogo(context, entryRoute));
  }

  void _pushLogo(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => TeamLogoStepScreen(
          onContinue: () => _pushCityGround(pageContext, entryRoute),
        ),
      ),
    );
  }

  void _pushCityGround(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => TeamCityGroundStepScreen(
          onContinue: () => _pushFormat(pageContext, entryRoute),
        ),
      ),
    );
  }

  void _pushFormat(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => TeamFormatStepScreen(
          onContinue: () => _pushJoinPolicy(pageContext, entryRoute),
        ),
      ),
    );
  }

  void _pushJoinPolicy(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => TeamJoinPolicyStepScreen(
          onContinue: () => _pushColors(pageContext, entryRoute),
        ),
      ),
    );
  }

  void _pushColors(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => TeamColorsStepScreen(
          onCreated: (team) => _pushCreated(pageContext, entryRoute, team),
        ),
      ),
    );
  }

  void _pushCreated(
    BuildContext context,
    Route<dynamic>? entryRoute,
    Team team,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => TeamCreatedScreen(
          team: team,
          onDone: () {
            onTeamCreated(team);
            final navigator = Navigator.of(pageContext);
            if (entryRoute != null) {
              navigator.popUntil((route) => route == entryRoute);
            }
            navigator.pop();
          },
        ),
      ),
    );
  }
}
