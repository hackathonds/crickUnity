import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/profile_wizard_provider.dart' show PrimaryRole;
import '../persistence/persisted_notifier.dart';
import 'selection_board_models.dart';

class SelectionBoardState {
  final List<PlayerCandidate> pool;
  final List<PlayerCandidate?> xi;
  final bool locked;
  final bool published;
  final List<String>? publishedSelected;
  final List<String>? publishedBenched;
  final List<ReplacementRequest> replacementRequests;

  const SelectionBoardState({
    this.pool = const [],
    this.xi = const [],
    this.locked = false,
    this.published = false,
    this.publishedSelected,
    this.publishedBenched,
    this.replacementRequests = const [],
  });

  /// DS's only concrete role-balance example: "warns amber ('No
  /// wicketkeeper selected')." No numeric bowler-count threshold is
  /// specified anywhere in either frozen document, so only this one
  /// check is implemented rather than an invented minimum.
  bool get hasWicketKeeper =>
      xi.any((p) => p?.role == PrimaryRole.wicketKeeper);

  int get filledSlotCount => xi.where((p) => p != null).length;

  bool get canPublish => filledSlotCount == xiSlotCount && !published;

  SelectionBoardState copyWith({
    List<PlayerCandidate>? pool,
    List<PlayerCandidate?>? xi,
    bool? locked,
    bool? published,
    List<String>? publishedSelected,
    List<String>? publishedBenched,
    List<ReplacementRequest>? replacementRequests,
  }) {
    return SelectionBoardState(
      pool: pool ?? this.pool,
      xi: xi ?? this.xi,
      locked: locked ?? this.locked,
      published: published ?? this.published,
      publishedSelected: publishedSelected ?? this.publishedSelected,
      publishedBenched: publishedBenched ?? this.publishedBenched,
      replacementRequests: replacementRequests ?? this.replacementRequests,
    );
  }

  Map<String, dynamic> toJson() => {
    'pool': pool.map((p) => p.toJson()).toList(),
    'xi': xi.map((p) => p?.toJson()).toList(),
    'locked': locked,
    'published': published,
    'publishedSelected': publishedSelected,
    'publishedBenched': publishedBenched,
    'replacementRequests': replacementRequests.map((r) => r.toJson()).toList(),
  };

  factory SelectionBoardState.fromJson(Map<String, dynamic> json) {
    return SelectionBoardState(
      pool: [
        for (final p in (json['pool'] as List? ?? const []))
          PlayerCandidate.fromJson(p as Map<String, dynamic>),
      ],
      xi: [
        for (final p in (json['xi'] as List? ?? const []))
          p == null
              ? null
              : PlayerCandidate.fromJson(p as Map<String, dynamic>),
      ],
      locked: json['locked'] as bool? ?? false,
      published: json['published'] as bool? ?? false,
      publishedSelected: (json['publishedSelected'] as List?)?.cast<String>(),
      publishedBenched: (json['publishedBenched'] as List?)?.cast<String>(),
      replacementRequests: [
        for (final r in (json['replacementRequests'] as List? ?? const []))
          ReplacementRequest.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §7.3-7.5: "Selection board: available players as draggable cards
/// -> Playing XI/XII + bench ... Publish lineup -> selected/benched get
/// distinct notifications; lineup locks at toss (post-lock changes =
/// 'replacement' flow requiring opponent captain acknowledgment,
/// logged)."
class SelectionBoardNotifier extends PersistedNotifier<SelectionBoardState> {
  @override
  String get persistenceKey => 'selection_board_v1';

  @override
  SelectionBoardState seed() => SelectionBoardState(
    pool: mockSelectionPool(),
    xi: List<PlayerCandidate?>.filled(xiSlotCount, null),
  );

  @override
  Map<String, dynamic> toJson(SelectionBoardState value) => value.toJson();

  @override
  SelectionBoardState fromJson(Map<String, dynamic> json) =>
      SelectionBoardState.fromJson(json);

  /// Returns null on success; a human-readable denial reason otherwise.
  String? selectToSlot(PlayerCandidate player, int slotIndex) {
    if (state.locked) {
      return 'The lineup is locked -- use the Replacement flow instead.';
    }
    if (state.xi[slotIndex] != null) {
      return 'That slot is already filled.';
    }
    final newXi = [...state.xi];
    newXi[slotIndex] = player;
    state = state.copyWith(
      pool: state.pool.where((p) => p.name != player.name).toList(),
      xi: newXi,
    );
    return null;
  }

  String? removeFromSlot(int slotIndex) {
    if (state.locked) {
      return 'The lineup is locked -- use the Replacement flow instead.';
    }
    final player = state.xi[slotIndex];
    if (player == null) return null;
    final newXi = [...state.xi];
    newXi[slotIndex] = null;
    state = state.copyWith(pool: [...state.pool, player], xi: newXi);
    return null;
  }

  /// Returns null on success; a denial reason otherwise.
  String? publishLineup() {
    if (!state.canPublish) {
      return 'Fill all $xiSlotCount slots before publishing.';
    }
    state = state.copyWith(
      published: true,
      publishedSelected: [for (final p in state.xi) p!.name],
      publishedBenched: [for (final p in state.pool) p.name],
    );
    return null;
  }

  void lockAtToss() {
    state = state.copyWith(locked: true);
  }

  String? requestReplacement({
    required String outgoingName,
    required String incomingName,
    required String reason,
  }) {
    if (!state.locked) {
      return 'The lineup isn\'t locked yet -- edit it directly instead.';
    }
    state = state.copyWith(
      replacementRequests: [
        ...state.replacementRequests,
        ReplacementRequest(
          id: 'repl-${state.replacementRequests.length + 1}',
          outgoingName: outgoingName,
          incomingName: incomingName,
          reason: reason,
        ),
      ],
    );
    return null;
  }

  /// PRD: "requiring opponent captain acknowledgment, logged." Once
  /// acknowledged, the swap actually takes effect in the XI.
  void acknowledgeReplacement(String requestId) {
    final request = state.replacementRequests.firstWhere(
      (r) => r.id == requestId,
    );
    final incoming = state.pool.firstWhere(
      (p) => p.name == request.incomingName,
    );
    final newXi = [
      for (final p in state.xi)
        if (p?.name == request.outgoingName) incoming else p,
    ];
    final newPool = [
      for (final p in state.pool)
        if (p.name != request.incomingName) p,
    ];
    state = state.copyWith(
      xi: newXi,
      pool: newPool,
      replacementRequests: [
        for (final r in state.replacementRequests)
          if (r.id == requestId)
            ReplacementRequest(
              id: r.id,
              outgoingName: r.outgoingName,
              incomingName: r.incomingName,
              reason: r.reason,
              acknowledged: true,
            )
          else
            r,
      ],
    );
  }
}

final selectionBoardProvider =
    NotifierProvider<SelectionBoardNotifier, SelectionBoardState>(
      SelectionBoardNotifier.new,
    );
