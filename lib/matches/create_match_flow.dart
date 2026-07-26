import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_match_basics_step_screen.dart';
import 'create_match_ground_time_step_screen.dart';
import 'create_match_opponent_step_screen.dart';
import 'create_match_provider.dart';
import 'create_match_review_step_screen.dart';
import 'match_pending_screen.dart';

/// PRD §7.1's 4-step create-match wizard, chained via plain Navigator
/// pushes -- same pattern as `create_team_flow.dart`.
class CreateMatchFlow extends StatelessWidget {
  final String composerTeamName;
  final ValueChanged<String> onMatchSent;

  const CreateMatchFlow({
    super.key,
    required this.composerTeamName,
    required this.onMatchSent,
  });

  @override
  Widget build(BuildContext context) {
    final entryRoute = ModalRoute.of(context);
    return CreateMatchBasicsStepScreen(
      onContinue: () => _pushOpponent(context, entryRoute),
    );
  }

  void _pushOpponent(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => CreateMatchOpponentStepScreen(
          onContinue: () => _pushGroundTime(pageContext, entryRoute),
        ),
      ),
    );
  }

  void _pushGroundTime(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => CreateMatchGroundTimeStepScreen(
          onContinue: () => _pushReview(pageContext, entryRoute),
        ),
      ),
    );
  }

  void _pushReview(BuildContext context, Route<dynamic>? entryRoute) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => CreateMatchReviewStepScreen(
          composerTeamName: composerTeamName,
          onSend: (matchId) => _pushPending(pageContext, entryRoute, matchId),
        ),
      ),
    );
  }

  void _pushPending(
    BuildContext context,
    Route<dynamic>? entryRoute,
    String matchId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => Consumer(
          builder: (pageContext, ref, _) {
            final opponentName = ref
                .read(createMatchProvider)
                .draft
                .opponentTeamName;
            return MatchPendingScreen(
              opponentTeamName: opponentName,
              onDone: () {
                onMatchSent(matchId);
                final navigator = Navigator.of(pageContext);
                if (entryRoute != null) {
                  navigator.popUntil((route) => route == entryRoute);
                }
                navigator.pop();
              },
            );
          },
        ),
      ),
    );
  }
}
