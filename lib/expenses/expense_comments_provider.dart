import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// Backlog addendum (E5-11) -- participant-only comment threads.
class ExpenseCommentsNotifier extends Notifier<ExpenseCommentsState> {
  int _nextId = 0;

  @override
  ExpenseCommentsState build() => const ExpenseCommentsState();

  void addComment({
    required String expenseId,
    required String authorName,
    required String text,
    required List<String> participantNames,
    DateTime Function() now = DateTime.now,
  }) {
    final comment = ExpenseComment(
      id: 'comment-${_nextId++}',
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
