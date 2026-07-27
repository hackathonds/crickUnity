import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'registration_models.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

class RegistrationsState {
  final List<TeamRegistration> registrations;

  const RegistrationsState({this.registrations = const []});

  RegistrationsState copyWith({List<TeamRegistration>? registrations}) =>
      RegistrationsState(registrations: registrations ?? this.registrations);

  List<TeamRegistration> forTournament(String tournamentId) =>
      registrations.where((r) => r.tournamentId == tournamentId).toList();
}

/// Backlog E10-02 -- Registration + escrow + eligibility flags engine.
/// See registration_models.dart's top-of-file note for the exact PRD
/// §8.2 quote this implements.
class RegistrationsNotifier extends Notifier<RegistrationsState> {
  @override
  RegistrationsState build() => const RegistrationsState();

  /// PRD §8.2: "squad list (min/max enforced)." Squad-size bounds come
  /// from the tournament's own Format step (E10-01), a genuine
  /// cross-story read rather than a re-declared limit.
  ///
  /// Returns null on success, or a validation message.
  String? registerTeam({
    required String tournamentId,
    required String teamName,
    required List<String> squad,
    required Set<String> docsChecked,
    DateTime Function() now = DateTime.now,
  }) {
    final tournament = ref
        .read(tournamentsProvider)
        .tournamentById(tournamentId);
    if (tournament == null) return 'Tournament not found.';
    if (squad.length < tournament.squadCapMin ||
        squad.length > tournament.squadCapMax) {
      return 'Squad must be between ${tournament.squadCapMin} and ${tournament.squadCapMax} players.';
    }
    if (!commonRegistrationDocs.every(docsChecked.contains)) {
      return 'All required docs must be checked before registering.';
    }

    final existing = state.forTournament(tournamentId);
    final occupiedSlots = existing
        .where(
          (r) =>
              r.status == RegistrationStatus.pending ||
              r.status == RegistrationStatus.approved,
        )
        .length;
    final isWaitlisted = occupiedSlots >= tournament.teamCap;

    final registration = TeamRegistration(
      id: 'registration-${now().microsecondsSinceEpoch}',
      tournamentId: tournamentId,
      teamName: teamName,
      squad: squad,
      docsChecked: docsChecked,
      status: isWaitlisted
          ? RegistrationStatus.waitlisted
          : RegistrationStatus.pending,
      createdAt: now(),
      waitlistPosition: isWaitlisted
          ? existing
                    .where((r) => r.status == RegistrationStatus.waitlisted)
                    .length +
                1
          : null,
    );
    state = state.copyWith(
      registrations: [...state.registrations, registration],
    );
    return null;
  }

  /// PRD §8.2: "duplicate player across two registered teams is
  /// auto-flagged and blocked until resolved."
  Set<String> duplicatesFor(String tournamentId) =>
      duplicatePlayersAcross(state.forTournament(tournamentId));

  bool hasDuplicateConflict(TeamRegistration registration) {
    final duplicates = duplicatesFor(registration.tournamentId);
    return registration.squad.any(duplicates.contains);
  }

  /// Approval blocked while a duplicate conflict is unresolved or
  /// required docs are incomplete -- credits the entry fee into the
  /// tournament's escrow (PRD §8.2).
  String? approveRegistration(String registrationId) {
    final registration = state.registrations
        .where((r) => r.id == registrationId)
        .firstOrNull;
    if (registration == null) return 'Registration not found.';
    if (hasDuplicateConflict(registration)) {
      return 'Resolve the duplicate-player conflict before approving.';
    }
    if (!registration.docsComplete) {
      return 'All required docs must be checked before approving.';
    }
    final tournament = ref
        .read(tournamentsProvider)
        .tournamentById(registration.tournamentId);
    _update(
      registrationId,
      (r) => r.copyWith(status: RegistrationStatus.approved),
    );
    if (tournament != null) {
      ref
          .read(tournamentsProvider.notifier)
          .addToEscrow(tournament.id, tournament.entryFee);
    }
    return null;
  }

  /// PRD §8.2: "full refund if rejected/cancelled." No real payment
  /// gateway exists to issue the refund (flagged, same convention as
  /// other missing-payment-infra gaps) -- the status transition and
  /// waitlist promotion are the genuine parts of this rule.
  void rejectRegistration(String registrationId) {
    final registration = state.registrations
        .where((r) => r.id == registrationId)
        .firstOrNull;
    if (registration == null) return;
    _update(
      registrationId,
      (r) => r.copyWith(status: RegistrationStatus.rejected),
    );
    _promoteFromWaitlist(registration.tournamentId);
  }

  /// PRD §8.2: "organizer-set sliding scale for withdrawal." No exact
  /// scale is given -- withdrawalRefundFraction() is a flagged
  /// judgment call; the fraction is returned so the caller can show
  /// the refund amount, since no real payment gateway exists to apply
  /// it automatically.
  double withdrawRegistration(
    String registrationId,
    DateTime tournamentStart, {
    DateTime Function() now = DateTime.now,
  }) {
    final registration = state.registrations
        .where((r) => r.id == registrationId)
        .firstOrNull;
    if (registration == null) return 0;
    _update(
      registrationId,
      (r) => r.copyWith(status: RegistrationStatus.withdrawn),
    );
    _promoteFromWaitlist(registration.tournamentId);
    return withdrawalRefundFraction(tournamentStart, now());
  }

  /// PRD §8.2: "Waitlist auto-promotes on dropout."
  void _promoteFromWaitlist(String tournamentId) {
    final waitlisted =
        state
            .forTournament(tournamentId)
            .where((r) => r.status == RegistrationStatus.waitlisted)
            .toList()
          ..sort(
            (a, b) =>
                (a.waitlistPosition ?? 0).compareTo(b.waitlistPosition ?? 0),
          );
    if (waitlisted.isEmpty) return;
    final promoted = waitlisted.first;
    _update(
      promoted.id,
      (r) => r.copyWith(
        status: RegistrationStatus.pending,
        clearWaitlistPosition: true,
      ),
    );
  }

  /// PRD §8.3: "team blackout dates (teams may submit up to 2)."
  void setBlackoutDates(String registrationId, List<DateTime> dates) {
    _update(
      registrationId,
      (r) => r.copyWith(blackoutDates: dates.take(maxBlackoutDates).toList()),
    );
  }

  /// Organizer conflict-resolution action: remove a player from one
  /// side of a flagged duplicate.
  void removePlayerFromSquad(String registrationId, String playerName) {
    final registration = state.registrations
        .where((r) => r.id == registrationId)
        .firstOrNull;
    if (registration == null) return;
    state = state.copyWith(
      registrations: [
        for (final r in state.registrations)
          if (r.id == registrationId)
            TeamRegistration(
              id: r.id,
              tournamentId: r.tournamentId,
              teamName: r.teamName,
              squad: r.squad.where((p) => p != playerName).toList(),
              docsChecked: r.docsChecked,
              status: r.status,
              createdAt: r.createdAt,
              waitlistPosition: r.waitlistPosition,
              blackoutDates: r.blackoutDates,
            )
          else
            r,
      ],
    );
  }

  void _update(
    String registrationId,
    TeamRegistration Function(TeamRegistration) transform,
  ) {
    state = state.copyWith(
      registrations: [
        for (final r in state.registrations)
          if (r.id == registrationId) transform(r) else r,
      ],
    );
  }
}

final registrationsProvider =
    NotifierProvider<RegistrationsNotifier, RegistrationsState>(
      RegistrationsNotifier.new,
    );
