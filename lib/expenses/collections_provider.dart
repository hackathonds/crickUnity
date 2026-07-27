import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collection_models.dart';

class CollectionsState {
  final List<Collection> collections;

  const CollectionsState({this.collections = const []});

  CollectionsState copyWith({List<Collection>? collections}) {
    return CollectionsState(collections: collections ?? this.collections);
  }
}

/// PRD §11.5 -- E5-07's Collections (planned inflows).
class CollectionsNotifier extends Notifier<CollectionsState> {
  int _nextId = 0;

  @override
  CollectionsState build() => const CollectionsState();

  String createCollection({
    required String title,
    required int amountPerMember,
    required List<String> memberNames,
    required DateTime deadline,
    bool allowPartial = false,
  }) {
    final id = 'collection-${_nextId++}';
    state = state.copyWith(
      collections: [
        ...state.collections,
        Collection(
          id: id,
          title: title,
          amountPerMember: amountPerMember,
          memberNames: memberNames,
          deadline: deadline,
          allowPartial: allowPartial,
        ),
      ],
    );
    return id;
  }

  /// "partials allowed if enabled" -- a contribution above the
  /// remaining balance is clamped to what's actually still owed;
  /// partial amounts are rejected outright when the collection doesn't
  /// allow them.
  void contribute(String collectionId, String memberName, int amount) {
    state = state.copyWith(
      collections: [
        for (final c in state.collections)
          if (c.id == collectionId)
            _applyContribution(c, memberName, amount)
          else
            c,
      ],
    );
  }

  Collection _applyContribution(Collection c, String memberName, int amount) {
    final already = c.contributions[memberName] ?? 0;
    final remaining = c.amountPerMember - already;
    if (remaining <= 0) return c;
    if (!c.allowPartial && amount < remaining) return c;
    final applied = amount > remaining ? remaining : amount;
    return c.copyWith(
      contributions: {...c.contributions, memberName: already + applied},
    );
  }
}

final collectionsProvider =
    NotifierProvider<CollectionsNotifier, CollectionsState>(
      CollectionsNotifier.new,
    );
