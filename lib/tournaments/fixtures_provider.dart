import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'fixture_models.dart';
import 'registration_models.dart';
import 'tournaments_provider.dart';

class FixturesState {
  final List<Fixture> fixtures;
  final Map<String, List<VenueSlot>> venueSlotsByTournament;
  final Set<String> publishedTournamentIds;

  const FixturesState({
    this.fixtures = const [],
    this.venueSlotsByTournament = const {},
    this.publishedTournamentIds = const {},
  });

  FixturesState copyWith({
    List<Fixture>? fixtures,
    Map<String, List<VenueSlot>>? venueSlotsByTournament,
    Set<String>? publishedTournamentIds,
  }) {
    return FixturesState(
      fixtures: fixtures ?? this.fixtures,
      venueSlotsByTournament:
          venueSlotsByTournament ?? this.venueSlotsByTournament,
      publishedTournamentIds:
          publishedTournamentIds ?? this.publishedTournamentIds,
    );
  }

  List<Fixture> forTournament(String tournamentId) =>
      fixtures.where((f) => f.tournamentId == tournamentId).toList();

  List<VenueSlot> venueSlotsFor(String tournamentId) =>
      venueSlotsByTournament[tournamentId] ?? const [];

  Map<String, dynamic> toJson() => {
    'fixtures': [for (final f in fixtures) f.toJson()],
    'venueSlotsByTournament': {
      for (final entry in venueSlotsByTournament.entries)
        entry.key: [for (final v in entry.value) v.toJson()],
    },
    'publishedTournamentIds': publishedTournamentIds.toList(),
  };

  factory FixturesState.fromJson(Map<String, dynamic> json) {
    return FixturesState(
      fixtures: [
        for (final f in json['fixtures'] as List)
          Fixture.fromJson(f as Map<String, dynamic>),
      ],
      venueSlotsByTournament: {
        for (final entry
            in (json['venueSlotsByTournament'] as Map<String, dynamic>).entries)
          entry.key: [
            for (final v in entry.value as List)
              VenueSlot.fromJson(v as Map<String, dynamic>),
          ],
      },
      publishedTournamentIds: {
        for (final id in json['publishedTournamentIds'] as List) id as String,
      },
    );
  }
}

/// Backlog E10-03 -- Fixtures generator + editor engine. See
/// fixture_models.dart's top-of-file note for the exact PRD §8.3 quote
/// and the flagged judgment calls (rest gap, double-header cap, and
/// the self-contained venue-pool standing in for cross-module ground
/// availability).
class FixturesNotifier extends PersistedNotifier<FixturesState> {
  @override
  String get persistenceKey => 'fixtures_v1';

  @override
  FixturesState seed() => const FixturesState();

  @override
  Map<String, dynamic> toJson(FixturesState value) => value.toJson();

  @override
  FixturesState fromJson(Map<String, dynamic> json) =>
      FixturesState.fromJson(json);

  void addVenueSlot(String tournamentId, VenueSlot slot) {
    final current = state.venueSlotsFor(tournamentId);
    state = state.copyWith(
      venueSlotsByTournament: {
        ...state.venueSlotsByTournament,
        tournamentId: [...current, slot],
      },
    );
  }

  bool _blackoutViolated(TeamRegistration team, DateTime date) =>
      team.blackoutDates.any(
        (b) =>
            b.year == date.year && b.month == date.month && b.day == date.day,
      );

  bool _restGapViolated(
    String registrationId,
    DateTime date,
    List<Fixture> assigned,
  ) {
    for (final f in assigned) {
      if (!f.isScheduled) continue;
      if (f.homeRegistrationId != registrationId &&
          f.awayRegistrationId != registrationId) {
        continue;
      }
      final gap = date.difference(f.date!).inDays.abs();
      if (gap < minRestDaysBetweenMatches) return true;
    }
    return false;
  }

  bool _doubleHeaderViolated(
    String registrationId,
    DateTime date,
    List<Fixture> assigned,
  ) {
    final sameDay = assigned.where(
      (f) =>
          f.isScheduled &&
          f.date!.year == date.year &&
          f.date!.month == date.month &&
          f.date!.day == date.day &&
          (f.homeRegistrationId == registrationId ||
              f.awayRegistrationId == registrationId),
    );
    return sameDay.length >= maxMatchesPerTeamPerDay;
  }

  bool _venueDateTaken(VenueSlot slot, List<Fixture> assigned) => assigned.any(
    (f) =>
        f.isScheduled && f.venueName == slot.venueName && f.date == slot.date,
  );

  /// PRD §8.3: round-robin generation honoring ground availability
  /// (this tournament's own venue-slot pool), blackout dates, rest
  /// gaps, and double-header limits. Pairings that find no fitting
  /// slot are left unscheduled (venueName/date null) for the organizer
  /// to resolve via manual drag-adjust rather than silently dropped.
  void generateFixtures(
    String tournamentId,
    List<TeamRegistration> approvedTeams,
  ) {
    final slots = [...state.venueSlotsFor(tournamentId)]
      ..sort((a, b) => a.date.compareTo(b.date));
    final pairings = <(TeamRegistration, TeamRegistration)>[];
    for (var i = 0; i < approvedTeams.length; i++) {
      for (var j = i + 1; j < approvedTeams.length; j++) {
        pairings.add((approvedTeams[i], approvedTeams[j]));
      }
    }

    final generated = <Fixture>[];
    for (final (home, away) in pairings) {
      VenueSlot? chosen;
      for (final slot in slots) {
        if (_venueDateTaken(slot, generated)) continue;
        if (_blackoutViolated(home, slot.date) ||
            _blackoutViolated(away, slot.date)) {
          continue;
        }
        if (_restGapViolated(home.id, slot.date, generated)) continue;
        if (_restGapViolated(away.id, slot.date, generated)) continue;
        if (_doubleHeaderViolated(home.id, slot.date, generated)) continue;
        if (_doubleHeaderViolated(away.id, slot.date, generated)) continue;
        chosen = slot;
        break;
      }
      generated.add(
        Fixture(
          id: 'fixture-${tournamentId}_${home.id}_${away.id}',
          tournamentId: tournamentId,
          homeRegistrationId: home.id,
          homeTeamName: home.teamName,
          awayRegistrationId: away.id,
          awayTeamName: away.teamName,
          venueName: chosen?.venueName,
          date: chosen?.date,
        ),
      );
    }

    state = state.copyWith(
      fixtures: [
        for (final f in state.fixtures)
          if (f.tournamentId != tournamentId) f,
        ...generated,
      ],
    );
  }

  /// PRD §8.3: "Manual drag-adjust with conflict warnings ... any
  /// change -> change-record with reason + re-notify affected." Edits
  /// are never blocked (warnings only, per PRD's own wording) --
  /// returns the list of conflict warnings for the caller to surface.
  List<String> editFixture(
    String fixtureId,
    String newVenueName,
    DateTime newDate,
    String reason, {
    required TeamRegistration home,
    required TeamRegistration away,
    DateTime Function() now = DateTime.now,
  }) {
    final fixture = state.fixtures.where((f) => f.id == fixtureId).firstOrNull;
    if (fixture == null) return const ['Fixture not found.'];

    final others = state.fixtures.where((f) => f.id != fixtureId).toList();
    final warnings = <String>[
      if (_venueDateTaken(
        VenueSlot(venueName: newVenueName, date: newDate),
        others,
      ))
        'Another fixture already uses this venue and date.',
      if (_blackoutViolated(home, newDate))
        '${home.teamName} has a blackout date on this day.',
      if (_blackoutViolated(away, newDate))
        '${away.teamName} has a blackout date on this day.',
      if (_restGapViolated(home.id, newDate, others))
        '${home.teamName} would have less than $minRestDaysBetweenMatches day(s) rest.',
      if (_restGapViolated(away.id, newDate, others))
        '${away.teamName} would have less than $minRestDaysBetweenMatches day(s) rest.',
      if (_doubleHeaderViolated(home.id, newDate, others))
        '${home.teamName} would exceed the $maxMatchesPerTeamPerDay match/day limit.',
      if (_doubleHeaderViolated(away.id, newDate, others))
        '${away.teamName} would exceed the $maxMatchesPerTeamPerDay match/day limit.',
    ];

    state = state.copyWith(
      fixtures: [
        for (final f in state.fixtures)
          if (f.id == fixtureId)
            f.copyWith(
              venueName: newVenueName,
              date: newDate,
              changeHistory: [
                ...f.changeHistory,
                FixtureChangeRecord(
                  reason: reason,
                  changedAt: now(),
                  previousVenueName: f.venueName,
                  previousDate: f.date,
                ),
              ],
            )
          else
            f,
      ],
    );
    ref
        .read(tournamentsProvider.notifier)
        .markOrganizerActive(fixture.tournamentId);
    return warnings;
  }

  /// PRD §8.3: "Publishing notifies all squads." No real notification
  /// catalog is wired yet (E12-05's job) -- flagged, same convention as
  /// every other cross-module notification gap this session.
  void publishFixtures(String tournamentId) {
    state = state.copyWith(
      publishedTournamentIds: {...state.publishedTournamentIds, tournamentId},
    );
  }
}

final fixturesProvider = NotifierProvider<FixturesNotifier, FixturesState>(
  FixturesNotifier.new,
);
