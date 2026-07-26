import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'succession_models.dart';

class SuccessionActionResult {
  final String? error;

  const SuccessionActionResult({this.error});

  bool get succeeded => error == null;
}

class ExitResult {
  final bool blocked;
  final String? error;
  final String? note;

  const ExitResult({required this.blocked, this.error, this.note});
}

class SuccessionState {
  final String captainName;
  final String viceCaptainName;
  final String ownerName;
  final DateTime ownerLastActiveAt;
  final String? unavailableMatchLabel;
  final List<ElevationRecord> elevationLog;
  final OwnershipTransfer? pendingOwnershipTransfer;
  final InactivityPetition? pendingInactivityPetition;
  final bool teamArchived;

  const SuccessionState({
    required this.captainName,
    required this.viceCaptainName,
    required this.ownerName,
    required this.ownerLastActiveAt,
    this.unavailableMatchLabel,
    this.elevationLog = const [],
    this.pendingOwnershipTransfer,
    this.pendingInactivityPetition,
    this.teamArchived = false,
  });

  SuccessionState copyWith({
    String? captainName,
    String? ownerName,
    DateTime? ownerLastActiveAt,
    String? unavailableMatchLabel,
    bool clearUnavailableMatchLabel = false,
    List<ElevationRecord>? elevationLog,
    OwnershipTransfer? pendingOwnershipTransfer,
    bool clearPendingOwnershipTransfer = false,
    InactivityPetition? pendingInactivityPetition,
    bool clearPendingInactivityPetition = false,
    bool? teamArchived,
  }) {
    return SuccessionState(
      captainName: captainName ?? this.captainName,
      viceCaptainName: viceCaptainName,
      ownerName: ownerName ?? this.ownerName,
      ownerLastActiveAt: ownerLastActiveAt ?? this.ownerLastActiveAt,
      unavailableMatchLabel: clearUnavailableMatchLabel
          ? null
          : (unavailableMatchLabel ?? this.unavailableMatchLabel),
      elevationLog: elevationLog ?? this.elevationLog,
      pendingOwnershipTransfer: clearPendingOwnershipTransfer
          ? null
          : (pendingOwnershipTransfer ?? this.pendingOwnershipTransfer),
      pendingInactivityPetition: clearPendingInactivityPetition
          ? null
          : (pendingInactivityPetition ?? this.pendingInactivityPetition),
      teamArchived: teamArchived ?? this.teamArchived,
    );
  }
}

/// PRD §2.3/2.4/2.9 and the team edge cases in §6: captaincy/ownership
/// succession. See succession_models.dart's doc comment for why roles
/// are independent booleans rather than the single-value
/// `TeamMemberRole` enum used elsewhere.
class SuccessionNotifier extends Notifier<SuccessionState> {
  @override
  SuccessionState build() => SuccessionState(
    captainName: 'Rohan Kapoor',
    viceCaptainName: 'Kabir Singh',
    ownerName: 'Rohan Kapoor',
    ownerLastActiveAt: DateTime.now(),
  );

  /// PRD §2.4: "If Captain marks self 'Unavailable' for a match, VC
  /// automatically gains full match-day powers for that match only
  /// (auto-elevation, logged, notified to team)."
  void markCaptainUnavailable(
    String matchLabel, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      unavailableMatchLabel: matchLabel,
      elevationLog: [
        ElevationRecord(
          matchLabel: matchLabel,
          viceCaptainName: state.viceCaptainName,
          elevatedAt: now(),
        ),
        ...state.elevationLog,
      ],
    );
  }

  void markCaptainAvailable() {
    state = state.copyWith(clearUnavailableMatchLabel: true);
  }

  /// PRD §2.9: "transfer team ownership (7-day cooling period, notified
  /// to all members)."
  SuccessionActionResult initiateOwnershipTransfer(
    String newOwnerName, {
    DateTime Function() now = DateTime.now,
  }) {
    if (newOwnerName.trim().isEmpty) {
      return const SuccessionActionResult(
        error: 'Name who ownership should transfer to.',
      );
    }
    if (newOwnerName.trim() == state.ownerName) {
      return const SuccessionActionResult(error: 'Already the owner.');
    }
    state = state.copyWith(
      pendingOwnershipTransfer: OwnershipTransfer(
        newOwnerName: newOwnerName.trim(),
        initiatedAt: now(),
      ),
    );
    return const SuccessionActionResult();
  }

  void cancelOwnershipTransfer() {
    state = state.copyWith(clearPendingOwnershipTransfer: true);
  }

  SuccessionActionResult completeOwnershipTransfer({
    DateTime Function() now = DateTime.now,
  }) {
    final pending = state.pendingOwnershipTransfer;
    if (pending == null) {
      return const SuccessionActionResult(
        error: 'No ownership transfer is pending.',
      );
    }
    if (!pending.isCoolingComplete(now: now)) {
      return const SuccessionActionResult(
        error: 'The 7-day cooling period has not finished yet.',
      );
    }
    state = state.copyWith(
      ownerName: pending.newOwnerName,
      clearPendingOwnershipTransfer: true,
    );
    return const SuccessionActionResult();
  }

  /// PRD §2.9: "If an Owner account is inactive 180 days, Captain can
  /// petition ownership transfer; petition notifies Owner across
  /// channels with 30-day response window."
  SuccessionActionResult petitionInactiveOwner({
    DateTime Function() now = DateTime.now,
  }) {
    if (now().difference(state.ownerLastActiveAt).inDays <
        ownerInactivityThresholdDays) {
      return const SuccessionActionResult(
        error:
            'The owner has not been inactive for $ownerInactivityThresholdDays '
            'days yet.',
      );
    }
    state = state.copyWith(
      pendingInactivityPetition: InactivityPetition(initiatedAt: now()),
    );
    return const SuccessionActionResult();
  }

  void ownerRespondToPetition({DateTime Function() now = DateTime.now}) {
    state = state.copyWith(
      ownerLastActiveAt: now(),
      clearPendingInactivityPetition: true,
    );
  }

  void archiveTeam() {
    state = state.copyWith(teamArchived: true);
  }

  /// Team edge case (§6): "Captain leaving without transfer ->
  /// ownership escalation prompt to Owner; if Owner=Captain leaving,
  /// forced transfer wizard blocks exit until resolved or team archived
  /// with balances settled."
  ExitResult attemptExitTeam({required bool isCaptain, required bool isOwner}) {
    if (isCaptain && isOwner && !state.teamArchived) {
      return const ExitResult(
        blocked: true,
        error:
            'You are both Captain and Owner -- transfer captaincy/'
            'ownership or archive the team before you can leave.',
      );
    }
    if (isCaptain) {
      return const ExitResult(
        blocked: false,
        note: 'The Owner has been sent a captaincy-reassignment prompt.',
      );
    }
    return const ExitResult(blocked: false);
  }
}

final successionProvider =
    NotifierProvider<SuccessionNotifier, SuccessionState>(
      SuccessionNotifier.new,
    );
