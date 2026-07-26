import 'package:cricunity/teams/kit_inventory_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initiateHandover sets a pending recipient without transferring custody',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(kitInventoryProvider.notifier);

      final result = notifier.initiateHandover(
        'kit-1',
        'Kabir Singh',
        'Sana Iyer',
      );

      expect(result.succeeded, isTrue);
      final item = container
          .read(kitInventoryProvider)
          .items
          .firstWhere((i) => i.id == 'kit-1');
      expect(item.custodianName, 'Kabir Singh');
      expect(item.pendingRecipient, 'Sana Iyer');
    },
  );

  test('a non-custodian cannot initiate a hand-over', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(kitInventoryProvider.notifier);

    final result = notifier.initiateHandover(
      'kit-1',
      'Sana Iyer',
      'Priya Nair',
    );

    expect(result.succeeded, isFalse);
  });

  test('AC: custody only transfers once the pending recipient confirms', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(kitInventoryProvider.notifier);

    notifier.initiateHandover('kit-1', 'Kabir Singh', 'Sana Iyer');
    final confirmResult = notifier.confirmHandover('kit-1', 'Sana Iyer');

    expect(confirmResult.succeeded, isTrue);
    final item = container
        .read(kitInventoryProvider)
        .items
        .firstWhere((i) => i.id == 'kit-1');
    expect(item.custodianName, 'Sana Iyer');
    expect(item.pendingRecipient, isNull);
  });

  test('only the pending recipient can confirm the hand-over', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(kitInventoryProvider.notifier);

    notifier.initiateHandover('kit-1', 'Kabir Singh', 'Sana Iyer');
    final result = notifier.confirmHandover('kit-1', 'Priya Nair');

    expect(result.succeeded, isFalse);
    final item = container
        .read(kitInventoryProvider)
        .items
        .firstWhere((i) => i.id == 'kit-1');
    expect(item.custodianName, 'Kabir Singh');
  });
}
