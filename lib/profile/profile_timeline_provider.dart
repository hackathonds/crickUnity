import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/player_analytics_data.dart' show mockCareerMatches;
import '../persistence/persisted_notifier.dart';
import '../teams/members_roles_provider.dart';
import '../tournaments/ledger_provider.dart';
import '../tournaments/tournaments_provider.dart';
import 'profile_timeline_models.dart';

/// Reuses the same recurring viewer/team mock identities as every
/// other cross-module feature this session (notification_catalog.dart,
/// entity_analytics_screen.dart).
const String _viewerName = 'Deepak Sharma';
const String _myTeamName = 'Strikers CC';

/// PRD §5.19: "auto-generated" -- computed straight from real state in
/// other modules, not a stored/authored list.
///
/// [ProfileTimelineEntryType.joinedTeam] has no real join-date field
/// anywhere in this codebase (TeamMember/team_member_models.dart
/// tracks no joinedAt) -- flagged approximation: it's dated to the
/// career dataset's earliest match, same day as debut (AppTimeline
/// groups same-day entries under one header anyway), rather than
/// fabricating an unrelated date.
List<ProfileTimelineEntry> computeProfileTimelineEntries(WidgetRef ref) {
  final entries = <ProfileTimelineEntry>[];
  final matches = mockCareerMatches(DateTime.now())
    ..sort((a, b) => a.date.compareTo(b.date));

  if (matches.isNotEmpty) {
    final first = matches.first;
    entries.add(
      ProfileTimelineEntry(
        id: 'joined-team',
        type: ProfileTimelineEntryType.joinedTeam,
        date: first.date,
        title: 'Joined $_myTeamName',
      ),
    );
    entries.add(
      ProfileTimelineEntry(
        id: 'debut',
        type: ProfileTimelineEntryType.debut,
        date: first.date,
        title: 'Debut -- ${first.label}',
      ),
    );
    final firstFifty = matches.firstWhere(
      (m) => m.runsScored >= 50,
      orElse: () => first,
    );
    if (firstFifty.runsScored >= 50) {
      entries.add(
        ProfileTimelineEntry(
          id: 'first-fifty',
          type: ProfileTimelineEntryType.firstFifty,
          date: firstFifty.date,
          title:
              'First fifty -- ${firstFifty.runsScored} vs '
              '${firstFifty.label}',
        ),
      );
    }
  }

  // PRD §2.4/§6: captaincy is a real, if session-local, event --
  // members_roles_provider.dart's log only grows from actual role
  // changes made during this run (no seeded captaincy history exists),
  // so this fires once the viewer is genuinely promoted, same
  // "conditionally empty until the real event happens" pattern used
  // elsewhere (practice reminders, review replies).
  final roleLog = ref.read(membersRolesProvider).log;
  for (final entry in roleLog) {
    if (entry.targetName == _viewerName &&
        entry.action.contains('Captain') &&
        !entry.action.contains('Vice')) {
      entries.add(
        ProfileTimelineEntry(
          id: 'captaincy-${entry.timestamp.millisecondsSinceEpoch}',
          type: ProfileTimelineEntryType.captaincy,
          date: entry.timestamp,
          title: 'Named Captain of $_myTeamName',
        ),
      );
    }
  }

  final tournaments = ref.read(tournamentsProvider).tournaments;
  final payouts = ref
      .read(ledgerProvider)
      .payoutsByTournament
      .values
      .expand((list) => list);
  for (final payout in payouts) {
    if (payout.winnerTeamName != _myTeamName) continue;
    final tournament = tournaments
        .where((t) => t.id == payout.tournamentId)
        .firstOrNull;
    entries.add(
      ProfileTimelineEntry(
        id: 'championship-${payout.id}',
        type: ProfileTimelineEntryType.championship,
        date: payout.awardedAt,
        title: 'Won ${tournament?.name ?? payout.tournamentId}',
      ),
    );
  }

  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

class ProfileTimelineState {
  final Set<String> hiddenEntryIds;

  const ProfileTimelineState({this.hiddenEntryIds = const {}});

  ProfileTimelineState copyWith({Set<String>? hiddenEntryIds}) {
    return ProfileTimelineState(
      hiddenEntryIds: hiddenEntryIds ?? this.hiddenEntryIds,
    );
  }

  Map<String, dynamic> toJson() => {'hiddenEntryIds': hiddenEntryIds.toList()};

  factory ProfileTimelineState.fromJson(Map<String, dynamic> json) {
    return ProfileTimelineState(
      hiddenEntryIds: {
        for (final id in json['hiddenEntryIds'] as List) id as String,
      },
    );
  }
}

/// PRD §5.19: "user can hide individual entries." Purely local visual
/// preference -- no PRD wording ties it to a synced backend field.
class ProfileTimelineNotifier extends PersistedNotifier<ProfileTimelineState> {
  @override
  String get persistenceKey => 'profile_timeline_v1';

  @override
  ProfileTimelineState seed() => const ProfileTimelineState();

  @override
  Map<String, dynamic> toJson(ProfileTimelineState value) => value.toJson();

  @override
  ProfileTimelineState fromJson(Map<String, dynamic> json) =>
      ProfileTimelineState.fromJson(json);

  void hide(String entryId) {
    state = state.copyWith(hiddenEntryIds: {...state.hiddenEntryIds, entryId});
  }

  void unhide(String entryId) {
    state = state.copyWith(
      hiddenEntryIds: {...state.hiddenEntryIds}..remove(entryId),
    );
  }
}

final profileTimelineProvider =
    NotifierProvider<ProfileTimelineNotifier, ProfileTimelineState>(
      ProfileTimelineNotifier.new,
    );
