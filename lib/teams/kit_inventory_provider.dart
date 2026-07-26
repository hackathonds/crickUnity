import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kit_inventory_models.dart';

class HandoverResult {
  final String? error;

  const HandoverResult({this.error});

  bool get succeeded => error == null;
}

class KitInventoryState {
  final List<KitItem> items;

  const KitInventoryState({this.items = const []});

  KitInventoryState copyWith({List<KitItem>? items}) {
    return KitInventoryState(items: items ?? this.items);
  }
}

/// DS §7 screen 21 (Kit Inventory): "Kit rows show custody avatar +
/// [Hand over] flow (both confirm)." Custody only moves once the
/// current custodian initiates AND the proposed recipient confirms
/// receipt -- a single-sided action never transfers custody.
class KitInventoryNotifier extends Notifier<KitInventoryState> {
  @override
  KitInventoryState build() => KitInventoryState(items: mockKitItems());

  HandoverResult initiateHandover(
    String itemId,
    String fromName,
    String toName,
  ) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    if (item.custodianName != fromName) {
      return const HandoverResult(
        error: 'Only the current custodian can hand this item over.',
      );
    }
    if (toName == fromName) {
      return const HandoverResult(
        error: 'Choose someone else to hand over to.',
      );
    }
    if (item.pendingRecipient != null) {
      return const HandoverResult(error: 'A hand-over is already pending.');
    }
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id == itemId) i.copyWith(pendingRecipient: toName) else i,
      ],
    );
    return const HandoverResult();
  }

  HandoverResult confirmHandover(String itemId, String viewerName) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    if (item.pendingRecipient != viewerName) {
      return const HandoverResult(
        error: 'Only the pending recipient can confirm this hand-over.',
      );
    }
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id == itemId)
            i.copyWith(custodianName: viewerName, clearPendingRecipient: true)
          else
            i,
      ],
    );
    return const HandoverResult();
  }
}

final kitInventoryProvider =
    NotifierProvider<KitInventoryNotifier, KitInventoryState>(
      KitInventoryNotifier.new,
    );
