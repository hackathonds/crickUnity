import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'jersey_board_models.dart';

class JerseyBoardState {
  final List<JerseySizeSubmission> submissions;
  final JerseyOrderStatus orderStatus;

  /// PRD §6.13: "durable-goods flag → can amortize ('₹9,000 kit ÷ season
  /// across members')." No real expense-ledger integration exists yet
  /// (that's a separate future epic) -- this is a plain read-only
  /// per-member figure, not a real expense-split write.
  final int totalPriceRupees;

  const JerseyBoardState({
    this.submissions = const [],
    this.orderStatus = JerseyOrderStatus.collectingSizes,
    this.totalPriceRupees = 9000,
  });

  /// Numbers claimed by more than one member.
  Map<int, List<JerseySizeSubmission>> get numberConflicts {
    final byNumber = <int, List<JerseySizeSubmission>>{};
    for (final submission in submissions) {
      final number = submission.number;
      if (number == null) continue;
      byNumber.putIfAbsent(number, () => []).add(submission);
    }
    return {
      for (final entry in byNumber.entries)
        if (entry.value.length > 1) entry.key: entry.value,
    };
  }

  int? pricePerMember() =>
      submissions.isEmpty ? null : totalPriceRupees ~/ submissions.length;

  JerseyBoardState copyWith({
    List<JerseySizeSubmission>? submissions,
    JerseyOrderStatus? orderStatus,
  }) {
    return JerseyBoardState(
      submissions: submissions ?? this.submissions,
      orderStatus: orderStatus ?? this.orderStatus,
      totalPriceRupees: totalPriceRupees,
    );
  }

  Map<String, dynamic> toJson() => {
    'submissions': submissions.map((s) => s.toJson()).toList(),
    'orderStatus': orderStatus.name,
    'totalPriceRupees': totalPriceRupees,
  };

  factory JerseyBoardState.fromJson(Map<String, dynamic> json) {
    return JerseyBoardState(
      submissions: [
        for (final s in (json['submissions'] as List? ?? const []))
          JerseySizeSubmission.fromJson(s as Map<String, dynamic>),
      ],
      orderStatus: JerseyOrderStatus.values.byName(
        json['orderStatus'] as String? ??
            JerseyOrderStatus.collectingSizes.name,
      ),
      totalPriceRupees: json['totalPriceRupees'] as int? ?? 9000,
    );
  }
}

class JerseyBoardNotifier extends PersistedNotifier<JerseyBoardState> {
  @override
  String get persistenceKey => 'jersey_board_v1';

  @override
  JerseyBoardState seed() =>
      JerseyBoardState(submissions: mockJerseySubmissions());

  @override
  Map<String, dynamic> toJson(JerseyBoardState value) => value.toJson();

  @override
  JerseyBoardState fromJson(Map<String, dynamic> json) =>
      JerseyBoardState.fromJson(json);

  void submitSize({
    required String memberName,
    required String size,
    required String nameOnJersey,
    int? number,
    DateTime Function() now = DateTime.now,
  }) {
    final existing = state.submissions.indexWhere(
      (s) => s.memberName == memberName,
    );
    final submission = JerseySizeSubmission(
      memberName: memberName,
      size: size,
      nameOnJersey: nameOnJersey,
      number: number,
      joinedAt: existing >= 0 ? state.submissions[existing].joinedAt : now(),
    );
    final updated = [...state.submissions];
    if (existing >= 0) {
      updated[existing] = submission;
    } else {
      updated.add(submission);
    }
    state = state.copyWith(submissions: updated);
  }

  /// PRD: "claim-by-seniority suggestion" -- the earliest-joined member
  /// keeps the number; every other conflicting submission has its
  /// number cleared, pending resubmission.
  void resolveConflictBySeniority(int number) {
    final conflicting = state.numberConflicts[number];
    if (conflicting == null) return;
    final senior = conflicting.reduce(
      (a, b) => a.joinedAt.isBefore(b.joinedAt) ? a : b,
    );
    state = state.copyWith(
      submissions: [
        for (final submission in state.submissions)
          if (submission.number == number &&
              submission.memberName != senior.memberName)
            submission.copyWith(clearNumber: true)
          else
            submission,
      ],
    );
  }

  /// Returns null on success; a denial reason if the sequence would be
  /// skipped (e.g. jumping straight to Distributed from Collecting).
  String? advanceOrderStatus() {
    final index = jerseyOrderStatusSequence.indexOf(state.orderStatus);
    if (index >= jerseyOrderStatusSequence.length - 1) {
      return 'Already at the final stage.';
    }
    state = state.copyWith(orderStatus: jerseyOrderStatusSequence[index + 1]);
    return null;
  }
}

final jerseyBoardProvider =
    NotifierProvider<JerseyBoardNotifier, JerseyBoardState>(
      JerseyBoardNotifier.new,
    );
