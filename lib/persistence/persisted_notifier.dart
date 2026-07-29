import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';

/// A [Notifier] whose entire state round-trips through [LocalStore] on
/// every change, instead of living only in memory. Concrete subclasses
/// replace [Notifier.build] with [seed] (the existing mock-data starting
/// point, used only the first time -- once anything is saved, [fromJson]
/// takes over) and add [toJson]/[fromJson] for their state type.
///
/// Existing mutator methods (`state = state.copyWith(...)`) need no
/// changes at all: overriding the [state] setter here means every write
/// persists automatically, the same way it already updates every listener.
///
/// Not every provider's state should use this wholesale -- some mix a
/// durable fact with a genuinely per-session one (see `guest_provider.dart`
/// for a provider that persists only part of its state by hand instead).
/// Use this base class when the *whole* state is meant to survive a
/// restart.
abstract class PersistedNotifier<T> extends Notifier<T> {
  /// Must be stable and unique across the whole app -- this is the
  /// [LocalStore] key this provider's state is saved under.
  String get persistenceKey;

  Map<String, dynamic> toJson(T value);

  T fromJson(Map<String, dynamic> json);

  /// The pre-persistence starting state (today's mock/demo seed) -- used
  /// only when nothing has been saved yet, e.g. a genuinely fresh install.
  T seed();

  @override
  T build() {
    final saved = ref.read(localStoreProvider).readJson(persistenceKey);
    if (saved != null) {
      try {
        return fromJson(saved);
      } catch (_) {
        // A previous app version saved a shape this version's fromJson
        // can't parse -- fall back to the seed rather than crash on boot.
      }
    }
    return seed();
  }

  @override
  set state(T value) {
    super.state = value;
    ref.read(localStoreProvider).writeJson(persistenceKey, toJson(value));
  }
}
