import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
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

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory KitInventoryState.fromJson(Map<String, dynamic> json) {
    return KitInventoryState(
      items: [
        for (final i in (json['items'] as List? ?? const []))
          KitItem.fromJson(i as Map<String, dynamic>),
      ],
    );
  }
}

/// DS §7 screen 21 (Kit Inventory): "Kit rows show custody avatar +
/// [Hand over] flow (both confirm)." Custody only moves once the
/// current custodian initiates AND the proposed recipient confirms
/// receipt -- a single-sided action never transfers custody.
class KitInventoryNotifier extends PersistedNotifier<KitInventoryState> {
  @override
  String get persistenceKey => 'kit_inventory_v1';

  @override
  KitInventoryState seed() => KitInventoryState(items: mockKitItems());

  @override
  Map<String, dynamic> toJson(KitInventoryState value) => value.toJson();

  @override
  KitInventoryState fromJson(Map<String, dynamic> json) =>
      KitInventoryState.fromJson(json);

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
