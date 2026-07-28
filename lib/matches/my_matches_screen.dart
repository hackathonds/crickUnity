import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_match_card.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_spacing.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'create_match_flow.dart';
import 'match_detail_screen.dart';
import 'match_models.dart';
import 'matches_provider.dart';
import 'scorecard_screen.dart';
import 'scoring_provider.dart';
import 'live_match_view_screen.dart';

enum _MatchesTab { upcoming, live, recent }

const Map<_MatchesTab, String> _tabLabels = {
  _MatchesTab.upcoming: 'Upcoming',
  _MatchesTab.live: 'Live',
  _MatchesTab.recent: 'Recent',
};

/// The demo "self" team every create-match/join flow in this app composes
/// on behalf of (same convention as `mockTeam()`'s callers elsewhere).
const _composerTeamName = 'Lions CC';

/// DS §7 screen 23 ("My Matches"): "Segmented Upcoming/Live/Recent; cards
/// per §3.2.2-3; empty per tab ('Find a game' links Discover)." No
/// Discover/browse-matches screen exists anywhere in this codebase
/// (flagged, same honest-gap convention as other missing cross-epic
/// destinations) -- [CreateMatchFlow] is this app's real, already-built
/// equivalent of "find a game" and stands in as the empty-state action.
///
/// This codebase models a single global scorer console
/// (scoring_provider.dart's one `inningsProvider`), not a per-match
/// innings map, and `MatchRecord` itself carries no "is this the one
/// that's live" signal -- so, same convention as `LiveMatchesBody`
/// (cricket_home_widgets.dart) and the home dashboard's own
/// `hasLiveMatch`, the Live tab reflects that one global console rather
/// than picking a specific match out of the list.
class MyMatchesScreen extends ConsumerStatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  ConsumerState<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends ConsumerState<MyMatchesScreen> {
  _MatchesTab _tab = _MatchesTab.upcoming;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final myMatches = ref
        .watch(matchesProvider)
        .matches
        .where((m) => m.squadNames.contains(composerViewerName))
        .toList();
    final innings = ref.watch(inningsProvider);
    final hasLiveMatch =
        !innings.isFullyConfirmed && innings.deliveries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('My Matches')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppSegmentedControl<_MatchesTab>(
              options: _MatchesTab.values,
              value: _tab,
              labelBuilder: (t) => _tabLabels[t]!,
              onChanged: (t) => setState(() => _tab = t),
            ),
          ),
          Expanded(child: _buildTabBody(myMatches, now, hasLiveMatch)),
        ],
      ),
    );
  }

  Widget _buildTabBody(
    List<MatchRecord> myMatches,
    DateTime now,
    bool hasLiveMatch,
  ) {
    switch (_tab) {
      case _MatchesTab.upcoming:
        final upcoming =
            myMatches
                .where(
                  (m) =>
                      m.status != MatchStatus.cancelled &&
                      m.status != MatchStatus.declined &&
                      m.draft.dateTime.isAfter(now),
                )
                .toList()
              ..sort((a, b) => a.draft.dateTime.compareTo(b.draft.dateTime));
        if (upcoming.isEmpty) {
          return _emptyState(
            key: 'myMatchesUpcomingEmptyState',
            message: "You don't have any matches lined up yet.",
            primaryLabel: 'Create match',
            onPrimary: _openCreateMatch,
          );
        }
        return _matchList(upcoming, now);

      case _MatchesTab.live:
        if (!hasLiveMatch) {
          return _emptyState(
            key: 'myMatchesLiveEmptyState',
            message: 'No match is live right now.',
            primaryLabel: 'See upcoming matches',
            onPrimary: () => setState(() => _tab = _MatchesTab.upcoming),
          );
        }
        final innings = ref.watch(inningsProvider);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppLiveMatchCard(
              teamAName: innings.battingTeamName,
              teamBName: innings.bowlingTeamName,
              scoreLine:
                  '${innings.battingTeamName} ${innings.totalRuns}/'
                  '${innings.wicketsLost}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveMatchViewScreen()),
              ),
            ),
          ],
        );

      case _MatchesTab.recent:
        final recent =
            myMatches
                .where(
                  (m) =>
                      m.status == MatchStatus.cancelled ||
                      m.status == MatchStatus.declined ||
                      m.draft.dateTime.isBefore(now),
                )
                .toList()
              ..sort((a, b) => b.draft.dateTime.compareTo(a.draft.dateTime));
        if (recent.isEmpty) {
          return _emptyState(
            key: 'myMatchesRecentEmptyState',
            message: "You haven't played any matches yet.",
            primaryLabel: 'Create match',
            onPrimary: _openCreateMatch,
          );
        }
        return _matchList(recent, now);
    }
  }

  Widget _emptyState({
    required String key,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppEmptyState(
        key: ValueKey(key),
        message: message,
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
      ),
    );
  }

  Widget _matchList(List<MatchRecord> matches, DateTime now) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final match in matches)
          Padding(
            key: ValueKey('myMatchCard_${match.id}'),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppMatchCard(
              teamAName: match.composerTeamName,
              teamBName: match.draft.opponentTeamName,
              format: match.draft.format.label,
              dateGroundLine:
                  '${_formatDateTime(match.draft.dateTime)} · '
                  '${match.draft.groundName}',
              squadLockCaption: '${match.squadNames.length} in squad',
              statusRail: _railFor(match, now),
              onTap: () => _openMatch(match, now),
            ),
          ),
      ],
    );
  }

  AppMatchStatusRail _railFor(MatchRecord match, DateTime now) {
    if (match.status == MatchStatus.cancelled ||
        match.status == MatchStatus.declined) {
      return AppMatchStatusRail.cancelled;
    }
    if (match.draft.dateTime.isBefore(now)) return AppMatchStatusRail.done;
    if (match.availabilityPollSent &&
        !match.availabilityResponses.containsKey(composerViewerName)) {
      return AppMatchStatusRail.responseNeeded;
    }
    return AppMatchStatusRail.lockedIn;
  }

  void _openMatch(MatchRecord match, DateTime now) {
    final isCompleted =
        match.status == MatchStatus.accepted &&
        match.draft.dateTime.isBefore(now);
    if (isCompleted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ScorecardScreen()));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(
          matchId: match.id,
          viewerName: composerViewerName,
        ),
      ),
    );
  }

  void _openCreateMatch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateMatchFlow(
          composerTeamName: _composerTeamName,
          onMatchSent: (_) {},
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${weekdays[dt.weekday - 1]} $hour12:$minute $period';
  }
}
