import 'package:cricunity/teams/jersey_board_models.dart';
import 'package:cricunity/teams/jersey_board_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with the mock submissions and Collecting sizes status', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(jerseyBoardProvider);

    expect(state.submissions, isNotEmpty);
    expect(state.orderStatus, JerseyOrderStatus.collectingSizes);
  });

  test('submitSize() adds a new submission', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(jerseyBoardProvider.notifier);

    notifier.submitSize(
      memberName: 'Ananya Iyer',
      size: 'S',
      nameOnJersey: 'IYER',
      number: 22,
    );

    final submission = container
        .read(jerseyBoardProvider)
        .submissions
        .firstWhere((s) => s.memberName == 'Ananya Iyer');
    expect(submission.size, 'S');
    expect(submission.number, 22);
  });

  test('resubmitting updates the existing entry instead of duplicating', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(jerseyBoardProvider.notifier);

    notifier.submitSize(
      memberName: 'Arjun Rao',
      size: 'XL',
      nameOnJersey: 'RAO',
      number: 7,
    );

    final matches = container
        .read(jerseyBoardProvider)
        .submissions
        .where((s) => s.memberName == 'Arjun Rao')
        .toList();
    expect(matches, hasLength(1));
    expect(matches.single.size, 'XL');
  });

  test('AC: a shared number is flagged as a conflict', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Mock data: Arjun Rao and Kabir Singh both claim #7.
    final conflicts = container.read(jerseyBoardProvider).numberConflicts;

    expect(conflicts.containsKey(7), isTrue);
    expect(
      conflicts[7]!.map((s) => s.memberName),
      containsAll(['Arjun Rao', 'Kabir Singh']),
    );
  });

  test('AC: resolveConflictBySeniority() keeps the earliest-joined member\'s '
      'number and clears the rest', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(jerseyBoardProvider.notifier);

    // Arjun Rao (joined 2023) is senior to Kabir Singh (joined 2024).
    notifier.resolveConflictBySeniority(7);

    final state = container.read(jerseyBoardProvider);
    expect(
      state.submissions.firstWhere((s) => s.memberName == 'Arjun Rao').number,
      7,
    );
    expect(
      state.submissions.firstWhere((s) => s.memberName == 'Kabir Singh').number,
      isNull,
    );
    expect(state.numberConflicts.containsKey(7), isFalse);
  });

  test('AC: advanceOrderStatus() moves sequentially through the stages', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(jerseyBoardProvider.notifier);

    for (final expected in [
      JerseyOrderStatus.ordered,
      JerseyOrderStatus.arrived,
      JerseyOrderStatus.distributed,
    ]) {
      final error = notifier.advanceOrderStatus();
      expect(error, isNull);
      expect(container.read(jerseyBoardProvider).orderStatus, expected);
    }

    final pastEnd = notifier.advanceOrderStatus();
    expect(pastEnd, isNotNull);
    expect(
      container.read(jerseyBoardProvider).orderStatus,
      JerseyOrderStatus.distributed,
    );
  });

  test('pricePerMember splits the total across current submissions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(jerseyBoardProvider);
    expect(
      state.pricePerMember(),
      state.totalPriceRupees ~/ state.submissions.length,
    );
  });
}
