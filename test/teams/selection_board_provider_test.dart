import 'package:cricunity/teams/selection_board_models.dart';
import 'package:cricunity/teams/selection_board_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with an empty XI and a full pool', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(selectionBoardProvider);

    expect(state.xi, everyElement(isNull));
    expect(state.pool, hasLength(greaterThanOrEqualTo(xiSlotCount)));
  });

  test('selectToSlot() moves a player from pool to the XI slot', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final player = container.read(selectionBoardProvider).pool.first;

    final error = notifier.selectToSlot(player, 0);

    expect(error, isNull);
    final state = container.read(selectionBoardProvider);
    expect(state.xi[0]!.name, player.name);
    expect(state.pool.any((p) => p.name == player.name), isFalse);
  });

  test('selectToSlot() rejects an already-filled slot', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final pool = container.read(selectionBoardProvider).pool;

    notifier.selectToSlot(pool[0], 0);
    final error = notifier.selectToSlot(pool[1], 0);

    expect(error, isNotNull);
  });

  test('removeFromSlot() returns the player to the pool', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final player = container.read(selectionBoardProvider).pool.first;
    notifier.selectToSlot(player, 0);

    notifier.removeFromSlot(0);

    final state = container.read(selectionBoardProvider);
    expect(state.xi[0], isNull);
    expect(state.pool.any((p) => p.name == player.name), isTrue);
  });

  test(
    'AC: hasWicketKeeper is false until a wicketkeeper is placed in the XI',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectionBoardProvider.notifier);
      expect(container.read(selectionBoardProvider).hasWicketKeeper, isFalse);

      final wk = container
          .read(selectionBoardProvider)
          .pool
          .firstWhere((p) => p.name == 'Meera Joshi');
      notifier.selectToSlot(wk, 0);

      expect(container.read(selectionBoardProvider).hasWicketKeeper, isTrue);
    },
  );

  test('publishLineup() fails until all 12 slots are filled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);

    final error = notifier.publishLineup();

    expect(error, isNotNull);
    expect(container.read(selectionBoardProvider).published, isFalse);
  });

  test('publishLineup() succeeds once full and splits selected vs benched', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final pool = List.of(container.read(selectionBoardProvider).pool);
    for (var i = 0; i < xiSlotCount; i++) {
      notifier.selectToSlot(pool[i], i);
    }

    final error = notifier.publishLineup();

    expect(error, isNull);
    final state = container.read(selectionBoardProvider);
    expect(state.published, isTrue);
    expect(state.publishedSelected, hasLength(xiSlotCount));
    expect(state.publishedBenched, hasLength(pool.length - xiSlotCount));
  });

  test('AC: once locked, direct slot edits are rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final pool = List.of(container.read(selectionBoardProvider).pool);
    notifier.selectToSlot(pool[0], 0);
    notifier.lockAtToss();

    final error = notifier.selectToSlot(pool[1], 1);

    expect(error, isNotNull);
  });

  test('AC: a replacement request needs acknowledgment before the swap takes '
      'effect', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final pool = List.of(container.read(selectionBoardProvider).pool);
    notifier.selectToSlot(pool[0], 0);
    notifier.lockAtToss();

    final error = notifier.requestReplacement(
      outgoingName: pool[0].name,
      incomingName: pool[1].name,
      reason: 'Injured',
    );
    expect(error, isNull);

    // Not yet acknowledged -- the XI is unchanged.
    var state = container.read(selectionBoardProvider);
    expect(state.xi[0]!.name, pool[0].name);
    expect(state.replacementRequests.single.acknowledged, isFalse);

    notifier.acknowledgeReplacement(state.replacementRequests.single.id);

    state = container.read(selectionBoardProvider);
    expect(state.xi[0]!.name, pool[1].name);
    expect(state.replacementRequests.single.acknowledged, isTrue);
  });

  test('requestReplacement() is rejected before the lineup is locked', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectionBoardProvider.notifier);
    final pool = container.read(selectionBoardProvider).pool;

    final error = notifier.requestReplacement(
      outgoingName: pool[0].name,
      incomingName: pool[1].name,
      reason: 'Injured',
    );

    expect(error, isNotNull);
  });
}
