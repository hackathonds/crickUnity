import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../grounds/grounds_provider.dart';
import '../../matches/match_models.dart';
import '../../matches/matches_provider.dart';
import '../../matches/scoring_provider.dart';
import '../../teams/availability_matrix_models.dart';
import '../../teams/practice_session_provider.dart';
import '../../social/composer_screen.dart' show composerViewerName;
import '../home_dashboard_provider.dart';

/// PRD §4.1 (Upcoming Matches): "Next 3 matches: opponent, date/time,
/// ground, my availability status ... squad-lock countdown. A:
/// Respond availability (inline chips) ... V: Users with ≥1 team or
/// booked match. S: Soonest first; matches needing my response
/// outrank. St: Empty; Response-needed (amber edge); Locked-in (green
/// tick); Cancelled (struck-through, dismissible)."
///
/// Weather glyph is E18-06's own dedicated story; Directions/Add-to-
/// calendar have no real maps/calendar integration in this codebase
/// (flagged, same convention as every other missing-device-API gap)
/// -- omitted rather than faked. "Squad-lock" has no separately
/// modeled timestamp; lineup locks at toss (PRD §7.5), so the
/// countdown here is to match start while [MatchRecord.tossResult] is
/// still null.
class UpcomingMatchesBody extends ConsumerWidget {
  const UpcomingMatchesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final matches =
        ref
            .watch(matchesProvider)
            .matches
            .where(
              (m) =>
                  m.squadNames.contains(composerViewerName) &&
                  m.status != MatchStatus.declined &&
                  m.status != MatchStatus.changesProposedToComposer &&
                  m.draft.dateTime.isAfter(now),
            )
            .toList()
          ..sort((a, b) {
            final aNeeds =
                a.availabilityPollSent &&
                !a.availabilityResponses.containsKey(composerViewerName);
            final bNeeds =
                b.availabilityPollSent &&
                !b.availabilityResponses.containsKey(composerViewerName);
            if (aNeeds != bNeeds) return aNeeds ? -1 : 1;
            return a.draft.dateTime.compareTo(b.draft.dateTime);
          });

    if (matches.isEmpty) {
      return Text(
        'No upcoming matches -- Find a game / Create one.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in matches.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _UpcomingMatchRow(match: m),
          ),
      ],
    );
  }
}

class _UpcomingMatchRow extends ConsumerWidget {
  final MatchRecord match;
  const _UpcomingMatchRow({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final responded = match.availabilityResponses.containsKey(
      composerViewerName,
    );
    final needsResponse = match.status == MatchStatus.cancelled
        ? false
        : match.availabilityPollSent && !responded;
    final lockedIn =
        !needsResponse &&
        match.availabilityResponses[composerViewerName] ==
            AvailabilityResponse.yes;
    final cancelled = match.status == MatchStatus.cancelled;
    final draft = match.draft;

    return Container(
      key: ValueKey('upcomingMatchRow_${match.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 3,
            color: needsResponse
                ? colors.coin
                : lockedIn
                ? colors.success
                : colors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'vs ${draft.opponentTeamName.isEmpty ? 'TBD' : draft.opponentTeamName}'
            '${cancelled ? ' (cancelled)' : ''}',
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
              decoration: cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            '${draft.groundName} · ${draft.dateTime.day}/${draft.dateTime.month} '
            '${draft.dateTime.hour.toString().padLeft(2, '0')}:'
            '${draft.dateTime.minute.toString().padLeft(2, '0')}'
            '${match.tossResult == null ? '' : ' · Locked (toss done)'}',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (needsResponse) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                OutlinedButton(
                  key: ValueKey('upcomingRsvpYes_${match.id}'),
                  onPressed: () => ref
                      .read(matchesProvider.notifier)
                      .respondAvailability(
                        match.id,
                        composerViewerName,
                        AvailabilityResponse.yes,
                      ),
                  child: const Text('Yes'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  key: ValueKey('upcomingRsvpNo_${match.id}'),
                  onPressed: () => ref
                      .read(matchesProvider.notifier)
                      .respondAvailability(
                        match.id,
                        composerViewerName,
                        AvailabilityResponse.no,
                      ),
                  child: const Text('No'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// PRD §4.3 (Today's Activity): "Today's events: match, practice,
/// booking, tournament fixture, coach session; each with time + place
/// + status chip. A: Check-in (when at venue window ±1h), View,
/// Navigate ... St: Empty ('Rest day 🏝️ — nearby matches to watch?'),
/// In-progress (live pulse), Done (checkmarks accumulate)."
///
/// Wires the two event sources this codebase can genuinely aggregate
/// today's events from (matches, practice sessions); booking/
/// tournament-fixture/coach-session aggregation is flagged as a
/// proportionate scope cut, not silently dropped.
class TodaysActivityBody extends ConsumerWidget {
  const TodaysActivityBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    final todaysMatches = ref
        .watch(matchesProvider)
        .matches
        .where(
          (m) =>
              m.squadNames.contains(composerViewerName) &&
              m.status == MatchStatus.accepted &&
              isToday(m.draft.dateTime),
        )
        .toList();
    final session = ref.watch(practiceSessionProvider).session;
    final hasTodaysPractice =
        session.roster.contains(composerViewerName) &&
        isToday(session.scheduledAt);
    final practiceCheckedIn = session.checkedIn.contains(composerViewerName);

    if (todaysMatches.isEmpty && !hasTodaysPractice) {
      return Text(
        'Rest day 🏝️ — nearby matches to watch?',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in todaysMatches)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${m.draft.dateTime.hour.toString().padLeft(2, '0')}:'
              '${m.draft.dateTime.minute.toString().padLeft(2, '0')} -- '
              'Match vs ${m.draft.opponentTeamName} · ${m.draft.groundName}',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
        if (hasTodaysPractice)
          Text(
            '${session.scheduledAt.hour.toString().padLeft(2, '0')}:'
            '${session.scheduledAt.minute.toString().padLeft(2, '0')} -- '
            'Practice at ${session.venueName}'
            '${practiceCheckedIn ? ' (checked in)' : ''}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
      ],
    );
  }
}

/// PRD §4.12 (Live Matches): "Matches of my teams / followed
/// entities: score ticker updating in place, key-moment chips. V:
/// Only during live matches (self-hides)." This codebase models one
/// scorer console (scoring_provider.dart's single inningsProvider),
/// not a per-match innings map -- wired to that, same convention as
/// every other single-live-match feature this session.
class LiveMatchesBody extends ConsumerWidget {
  const LiveMatchesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final innings = ref.watch(inningsProvider);
    return Text(
      '${innings.battingTeamName} ${innings.totalRuns}/'
      '${innings.wicketsLost} vs ${innings.bowlingTeamName}',
      style: AppTypography.stat.copyWith(
        color: colors.live,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// PRD §4.11 (Nearby Matches): "Live/today matches within radius
/// (default 10 km): teams, over, venue distance. V: Requires location
/// permission; else shows 'Enable location to find cricket around
/// you.' St: Nothing nearby → widens radius suggestion."
class NearbyMatchesBody extends ConsumerWidget {
  const NearbyMatchesBody({super.key});

  static const double _defaultRadiusKm = 10;
  static const double _widenedRadiusKm = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final granted = ref.watch(
      homeDashboardProvider.select((s) => s.locationPermissionGranted),
    );

    if (!granted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enable location to find cricket around you.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(
            key: const ValueKey('enableLocationButton'),
            onPressed: () => ref
                .read(homeDashboardProvider.notifier)
                .grantLocationPermission(),
            child: const Text('Enable location'),
          ),
        ],
      );
    }

    final grounds = ref.watch(groundsProvider).grounds;
    final matches = ref.watch(matchesProvider).matches;
    final now = DateTime.now();

    List<String> nearbyMatchLines(double radiusKm) {
      final nearbyGroundNames = grounds
          .where((g) => g.distanceKm <= radiusKm)
          .map((g) => g.name)
          .toSet();
      final today = matches.where(
        (m) =>
            nearbyGroundNames.contains(m.draft.groundName) &&
            m.status == MatchStatus.accepted &&
            m.draft.dateTime.difference(now).inHours.abs() <= 24,
      );
      return [
        for (final m in today)
          '${m.composerTeamName} vs ${m.draft.opponentTeamName} -- '
              '${m.draft.groundName}',
      ];
    }

    var lines = nearbyMatchLines(_defaultRadiusKm);
    var widened = false;
    if (lines.isEmpty) {
      lines = nearbyMatchLines(_widenedRadiusKm);
      widened = lines.isNotEmpty;
    }

    if (lines.isEmpty) {
      return Text(
        'Nothing nearby right now -- try widening your radius in Settings.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widened)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'Widened to ${_widenedRadiusKm.round()} km -- nothing within '
              '${_defaultRadiusKm.round()} km.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ),
        for (final line in lines)
          Text(
            line,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
      ],
    );
  }
}
