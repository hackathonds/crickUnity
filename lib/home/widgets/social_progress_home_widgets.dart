import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/attendance_analytics_models.dart' show mockAttendance;
import '../../analytics/player_analytics_data.dart' show mockCareerMatches;
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../grounds/grounds_provider.dart';
import '../../matches/match_models.dart';
import '../../matches/matches_provider.dart';
import '../../messaging/chat_provider.dart';
import '../../notifications/notification_provider.dart';
import '../../tournaments/fixtures_provider.dart';
import '../../tournaments/registrations_provider.dart';
import '../../tournaments/tournaments_provider.dart';
import '../../recognition/progress_ring_models.dart';
import '../../recognition/progress_rings_provider.dart';
import '../../recognition/rank_models.dart';
import '../../recognition/ranks_provider.dart';
import '../../rewards/achievements_provider.dart';
import '../../social/feed_provider.dart';

/// Reuses the app's recurring viewer-team mock identity (notification_
/// catalog.dart, entity_analytics_screen.dart).
const String _myTeamName = 'Strikers CC';

/// PRD §4.14 (Tournament Updates): "My/followed tournaments: next
/// fixture, points-table position delta, pending actions. St:
/// Action-required outranks informational." Not explicitly assigned to
/// any of E18-01..07 in the backlog's own split -- wired here rather
/// than left permanently uncovered, reusing the same real fixtures/
/// registrations read as notification_catalog.dart's tournament
/// cards. Points-table position delta has no historical snapshot
/// anywhere in this codebase (flagged, omitted).
class TournamentUpdatesBody extends ConsumerWidget {
  const TournamentUpdatesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final myRegistrations = ref
        .watch(registrationsProvider)
        .registrations
        .where((r) => r.teamName == _myTeamName)
        .toList();
    final tournaments = ref.watch(tournamentsProvider).tournaments;
    final fixtures = ref.watch(fixturesProvider).fixtures;

    final upcoming = <String>[];
    for (final r in myRegistrations) {
      final t = tournaments.where((t) => t.id == r.tournamentId).firstOrNull;
      if (t == null) continue;
      final next = fixtures
          .where(
            (f) =>
                f.tournamentId == r.tournamentId &&
                (f.homeRegistrationId == r.id ||
                    f.awayRegistrationId == r.id) &&
                f.isScheduled,
          )
          .firstOrNull;
      if (next != null) {
        upcoming.add(
          '${t.name}: next vs '
          '${next.homeTeamName == _myTeamName ? next.awayTeamName : next.homeTeamName}',
        );
      }
    }

    if (upcoming.isEmpty) {
      return Text(
        'No upcoming tournament fixtures.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in upcoming)
          Text(
            line,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
      ],
    );
  }
}

/// PRD §4.2 (Recent Performance): "Last match line (e.g. '38 (22) &
/// 1/24'), rating given, MVP flag, XP/coins earned chips. V: Players
/// with ≥1 completed match. St: Fresh (<24h); Stale (>7d: swaps to
/// season summary); Disputed (grey)." Rating/MVP/dispute-state have no
/// real per-match signal on [MatchPerformance] (flagged) -- the
/// scoreline and freshness state are real.
class RecentPerformanceBody extends ConsumerWidget {
  const RecentPerformanceBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final matches = mockCareerMatches(now)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (matches.isEmpty) return const SizedBox.shrink();
    final last = matches.first;
    final ageDays = now.difference(last.date).inDays;
    final ballsFaced = last.facedBalls.where((b) => b.delivery.isLegal).length;
    final runsConceded = last.bowledBalls.fold(
      0,
      (sum, b) => sum + b.delivery.runs,
    );
    final line =
        '${last.runsScored} ($ballsFaced)'
        '${last.wicketsTaken > 0 ? ' & ${last.wicketsTaken}/$runsConceded' : ''}';

    return Text(
      ageDays > 7 ? 'Season so far -- last: $line' : line,
      style: AppTypography.stat.copyWith(color: colors.textPrimary),
    );
  }
}

/// PRD §4.8-4.10 (Suggested Friends/Teams/Grounds): "Graph growth ...
/// V: collapses once graph is dense (≥50 follows)." Friends/Teams need
/// a mutual-connections and recruitment-matching graph that doesn't
/// exist anywhere in this codebase -- flagged, not guessed. Grounds
/// reuses real groundsProvider distance/rating data (the one of the
/// three with a genuine backing source).
class SuggestedFriendsBody extends StatelessWidget {
  const SuggestedFriendsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      'No mutual-connections graph exists in this codebase yet to '
      'derive real suggestions from.',
      style: AppTypography.caption.copyWith(color: colors.textTertiary),
    );
  }
}

class SuggestedTeamsBody extends StatelessWidget {
  const SuggestedTeamsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      'No recruitment-matching graph exists in this codebase yet to '
      'derive real suggestions from.',
      style: AppTypography.caption.copyWith(color: colors.textTertiary),
    );
  }
}

class SuggestedGroundsBody extends ConsumerWidget {
  const SuggestedGroundsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final grounds = ref.watch(groundsProvider).grounds.toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (grounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in grounds.take(2))
          Text(
            '${g.name} -- ${g.distanceKm}km · ${g.rating}★',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
      ],
    );
  }
}

/// PRD §4.20 (Recent Posts): "1-2 top posts from close graph since
/// last visit." No "close graph" relevance scoring is applied here
/// beyond feedProvider's own real [FeedPost.relationshipScore] (E7-01),
/// reused rather than re-derived.
class RecentPostsBody extends ConsumerWidget {
  const RecentPostsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final posts = ref.watch(feedProvider).posts.toList()
      ..sort((a, b) => b.relationshipScore.compareTo(a.relationshipScore));
    if (posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in posts.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${p.authorName}: ${p.contentText}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}

/// PRD §4.21 (Recent Achievements): "Latest badge/milestone of mine or
/// close friends." Real read of achievementsProvider.dart's timeline
/// (E6-04) -- friends' achievements would need a cross-user feed this
/// codebase doesn't model (single-viewer identity), so this shows the
/// viewer's own latest only.
class RecentAchievementsBody extends ConsumerWidget {
  const RecentAchievementsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final timeline = ref.watch(achievementsProvider).timeline;
    if (timeline.isEmpty) return const SizedBox.shrink();
    return Text(
      timeline.last,
      style: AppTypography.body.copyWith(color: colors.textPrimary),
    );
  }
}

/// PRD §4.15 (Followers): "weekly delta + notable follower ...
/// self-hides if no change." No follower-count-history snapshot
/// exists anywhere in this codebase to derive a real delta from
/// (flagged).
class FollowersDeltaBody extends StatelessWidget {
  const FollowersDeltaBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      'No follower-count history exists in this codebase yet to derive '
      'a real weekly delta from.',
      style: AppTypography.caption.copyWith(color: colors.textTertiary),
    );
  }
}

/// PRD §4.16 (Messages): "top 2 unread threads with preview. A: Reply
/// inline, Open. Hidden if zero unread." Real read of chatsProvider
/// (E15-05).
class MessagesPreviewBody extends ConsumerWidget {
  const MessagesPreviewBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final unreadChats = ref
        .watch(chatsProvider)
        .chats
        .where((c) => c.unreadCount > 0)
        .toList();
    if (unreadChats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in unreadChats.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${c.name}: ${c.lastMessage?.text ?? '${c.unreadCount} new'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}

/// PRD §4.17 (Invitations): "team invites, match invites, tournament
/// invites, academy offers as decision cards; each shows expiry
/// countdown." Only match invites (matchesProvider's real
/// pendingOpponent status) have a genuine backing signal in this
/// codebase -- team_invite_provider.dart only tracks the captain's own
/// outgoing link, not offers received; no tournament/academy-invite
/// inbox exists either (flagged).
class InvitationsBody extends ConsumerWidget {
  const InvitationsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final pending = ref
        .watch(matchesProvider)
        .matches
        .where((m) => m.status == MatchStatus.pendingOpponent)
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in pending)
          Text(
            'Match invite -- vs ${m.composerTeamName}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
      ],
    );
  }
}

/// PRD §4.18 (Unread Notifications): "Compact digest only when badge
/// >=5 and untouched >12h." No "last opened notification center"
/// timestamp exists in this codebase (flagged) -- gated on the count
/// half of the rule only.
class UnreadNotificationsBody extends ConsumerWidget {
  const UnreadNotificationsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cards = ref.watch(notificationProvider).cards;
    final unread = cards.where((c) => !c.read).toList();
    if (unread.length < 5) return const SizedBox.shrink();
    final needAction = unread.where((c) => c.isDecision).length;
    return Text(
      '${unread.length} unread · $needAction need action',
      style: AppTypography.body.copyWith(color: colors.textPrimary),
    );
  }
}

/// PRD §4.22 (Player Ranking): "My city/format rank + weekly
/// movement. V: Players with >=5 verified matches (below: progress-
/// to-ranked bar)." Real read of ranksProvider (E6-08); weekly
/// movement has no historical percentile snapshot in this codebase
/// (flagged, omitted rather than fabricated).
class PlayerRankingBody extends ConsumerWidget {
  const PlayerRankingBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final profiles = ref.watch(ranksProvider).profiles;
    final RankProfile? top = profiles.isEmpty
        ? null
        : profiles.reduce((a, b) => a.percentile >= b.percentile ? a : b);
    if (top == null) return const SizedBox.shrink();
    return Text(
      '${rankDisciplineLabels[top.discipline]} -- top ${100 - top.percentile}% '
      'in ${top.cityLabel} ${top.formatLabel}',
      style: AppTypography.body.copyWith(color: colors.textPrimary),
    );
  }
}

/// PRD §4.23 (Fitness Progress): "Weekly training ring
/// (sessions/target), streak. St: Ring closed (burst); broken streak
/// (gentle, never shaming)." Real read of progressRingsProvider (E8-08)
/// -- reuses the real [RingType.train] ring rather than a parallel one.
class FitnessProgressBody extends ConsumerWidget {
  const FitnessProgressBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ring = ref.watch(progressRingsProvider).ringFor(RingType.train);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ring.progress}/${ring.target} sessions this week',
          style: AppTypography.body.copyWith(color: colors.textPrimary),
        ),
        if (ring.closeStreak > 0)
          Text(
            '${ring.closeStreak}-week streak',
            style: AppTypography.caption.copyWith(color: colors.coin),
          ),
      ],
    );
  }
}

/// PRD §4.24 (Attendance): "My attendance % this season, team average
/// comparison. St: >=90% 'Iron Player' chip; <60% neutral tip." Reuses
/// attendance_analytics_models.dart's real (flagged-synthetic, no
/// attendance-history backend exists) dataset rather than a second
/// mock; team average has no aggregate in that same dataset (flagged,
/// omitted).
class AttendanceBody extends ConsumerWidget {
  const AttendanceBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final records = mockAttendance(DateTime.now());
    if (records.isEmpty) return const SizedBox.shrink();
    final attended = records.where((r) => r.attended).length;
    final pct = (attended / records.length * 100).round();

    return Row(
      children: [
        Text(
          '$pct% attendance',
          style: AppTypography.stat.copyWith(color: colors.textPrimary),
        ),
        if (pct >= 90) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.coin.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Iron Player',
              style: AppTypography.caption.copyWith(color: colors.coin),
            ),
          ),
        ],
      ],
    );
  }
}
