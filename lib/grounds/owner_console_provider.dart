import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'owner_console_models.dart';

class OwnerConsoleState {
  final List<MaintenanceBlock> maintenanceBlocks;
  final List<CaretakerAccount> staff;

  const OwnerConsoleState({
    this.maintenanceBlocks = const [],
    this.staff = const [],
  });

  OwnerConsoleState copyWith({
    List<MaintenanceBlock>? maintenanceBlocks,
    List<CaretakerAccount>? staff,
  }) {
    return OwnerConsoleState(
      maintenanceBlocks: maintenanceBlocks ?? this.maintenanceBlocks,
      staff: staff ?? this.staff,
    );
  }

  bool isBlocked(String groundId, DateTime slot) =>
      maintenanceBlocks.any((b) => b.coversSlot(groundId, slot));

  Map<String, dynamic> toJson() => {
    'maintenanceBlocks': [for (final b in maintenanceBlocks) b.toJson()],
    'staff': [for (final s in staff) s.toJson()],
  };

  factory OwnerConsoleState.fromJson(Map<String, dynamic> json) {
    return OwnerConsoleState(
      maintenanceBlocks: [
        for (final b in json['maintenanceBlocks'] as List)
          MaintenanceBlock.fromJson(b as Map<String, dynamic>),
      ],
      staff: [
        for (final s in json['staff'] as List)
          CaretakerAccount.fromJson(s as Map<String, dynamic>),
      ],
    );
  }
}

/// Backlog E9-05 -- Owner Console engine (PRD §10.6's Maintenance and
/// Staff sub-sections; occupancy/revenue/review-sentiment/price-nudges
/// are read-only derivations computed in owner_console_screen.dart from
/// the real bookingsProvider/reviewsProvider state, not stored here).
class OwnerConsoleNotifier extends PersistedNotifier<OwnerConsoleState> {
  @override
  String get persistenceKey => 'owner_console_v1';

  @override
  OwnerConsoleState seed() => const OwnerConsoleState();

  @override
  Map<String, dynamic> toJson(OwnerConsoleState value) => value.toJson();

  @override
  OwnerConsoleState fromJson(Map<String, dynamic> json) =>
      OwnerConsoleState.fromJson(json);

  void blockSlot({
    required String groundId,
    required DateTime slotStart,
    required String reason,
    bool recurringWeekly = false,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      maintenanceBlocks: [
        ...state.maintenanceBlocks,
        MaintenanceBlock(
          id: 'block-${now().microsecondsSinceEpoch}',
          groundId: groundId,
          slotStart: slotStart,
          reason: reason,
          recurringWeekly: recurringWeekly,
        ),
      ],
    );
  }

  void unblockSlot(String blockId) {
    state = state.copyWith(
      maintenanceBlocks: [
        for (final b in state.maintenanceBlocks)
          if (b.id != blockId) b,
      ],
    );
  }

  void addStaff(String name, {DateTime Function() now = DateTime.now}) {
    state = state.copyWith(
      staff: [
        ...state.staff,
        CaretakerAccount(
          id: 'staff-${now().microsecondsSinceEpoch}',
          name: name,
        ),
      ],
    );
  }

  void removeStaff(String staffId) {
    state = state.copyWith(
      staff: [
        for (final s in state.staff)
          if (s.id != staffId) s,
      ],
    );
  }
}

final ownerConsoleProvider =
    NotifierProvider<OwnerConsoleNotifier, OwnerConsoleState>(
      OwnerConsoleNotifier.new,
    );
