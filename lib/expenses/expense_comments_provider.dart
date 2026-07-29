import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'expense_comment_models.dart';

class ExpenseCommentsState {
  final Map<String, List<ExpenseComment>> byExpenseId;

  const ExpenseCommentsState({this.byExpenseId = const {}});

  List<ExpenseComment> commentsFor(String expenseId) =>
      byExpenseId[expenseId] ?? const [];

  ExpenseCommentsState copyWith({
    Map<String, List<ExpenseComment>>? byExpenseId,
  }) {
    return ExpenseCommentsState(byExpenseId: byExpenseId ?? this.byExpenseId);
  }

  Map<String, dynamic> toJson() => {
    'byExpenseId': {
      for (final entry in byExpenseId.entries)
        entry.key: [for (final c in entry.value) c.toJson()],
    },
  };

  factory ExpenseCommentsState.fromJson(Map<String, dynamic> json) {
    return ExpenseCommentsState(
      byExpenseId: {
        for (final entry
            in (json['byExpenseId'] as Map<String, dynamic>).entries)
          entry.key: [
            for (final c in entry.value as List)
              ExpenseComment.fromJson(c as Map<String, dynamic>),
          ],
      },
    );
  }
}

/// Backlog addendum (E5-11) -- participant-only comment threads.
class ExpenseCommentsNotifier extends PersistedNotifier<ExpenseCommentsState> {
  @override
  String get persistenceKey => 'expense_comments_v1';

  @override
  ExpenseCommentsState seed() => const ExpenseCommentsState();

  @override
  Map<String, dynamic> toJson(ExpenseCommentsState value) => value.toJson();

  @override
  ExpenseCommentsState fromJson(Map<String, dynamic> json) =>
      ExpenseCommentsState.fromJson(json);

  /// Computed from current state rather than a separate incrementing
  /// field -- a plain field would restart at 0 after every app restart
  /// and collide with ids already restored from disk.
  int get _nextId =>
      state.byExpenseId.values.fold(0, (sum, list) => sum + list.length);

  void addComment({
    required String expenseId,
    required String authorName,
    required String text,
    required List<String> participantNames,
    DateTime Function() now = DateTime.now,
  }) {
    final comment = ExpenseComment(
      id: 'comment-$_nextId',
      expenseId: expenseId,
      authorName: authorName,
      text: text,
      mentionedNames: parseMentions(text, participantNames),
      createdAt: now(),
    );
    state = state.copyWith(
      byExpenseId: {
        ...state.byExpenseId,
        expenseId: [...state.commentsFor(expenseId), comment],
      },
    );
  }
}

final expenseCommentsProvider =
    NotifierProvider<ExpenseCommentsNotifier, ExpenseCommentsState>(
      ExpenseCommentsNotifier.new,
    );
