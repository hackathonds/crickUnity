import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The seam between "a provider's state" and "wherever that state actually
/// lives." Every persisted provider talks to this interface, never to
/// [SharedPreferences] directly -- swapping local storage for a real API
/// later (per project direction) means writing one new [LocalStore]
/// implementation, not touching the ~100 providers that use it.
abstract class LocalStore {
  Map<String, dynamic>? readJson(String key);
  void writeJson(String key, Map<String, dynamic> json);
  void remove(String key);
}

/// Default implementation for every provider that hasn't been migrated to
/// real persistence yet, and for tests: a plain in-memory map, scoped to
/// whichever [ProviderContainer] holds it. Behaves exactly like this
/// codebase's pre-persistence Notifiers (fresh state every time a new
/// container is created), so this is a safe, zero-risk default -- nothing
/// regresses just because [localStoreProvider] exists.
class InMemoryLocalStore implements LocalStore {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  Map<String, dynamic>? readJson(String key) => _data[key];

  @override
  void writeJson(String key, Map<String, dynamic> json) => _data[key] = json;

  @override
  void remove(String key) => _data.remove(key);
}

/// The real, on-device implementation -- one JSON string per provider under
/// its own key. [SharedPreferences] caches its values in memory after the
/// first (async) load, so every call here is synchronous, which is what
/// lets a [Notifier.build()] read persisted state without itself becoming
/// async; `main()` is responsible for awaiting [SharedPreferences.getInstance]
/// once before the app's [ProviderScope] is built (see main.dart).
class SharedPreferencesLocalStore implements LocalStore {
  final SharedPreferences prefs;

  const SharedPreferencesLocalStore(this.prefs);

  @override
  Map<String, dynamic>? readJson(String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Corrupted or stale-shape value from a previous app version --
      // treated as "nothing saved" rather than crashing the app.
      return null;
    }
  }

  @override
  void writeJson(String key, Map<String, dynamic> json) {
    // Fire-and-forget: SharedPreferences' own in-memory cache updates
    // synchronously as part of this call, so a readJson() immediately
    // after sees the new value regardless of when the underlying platform
    // write actually completes.
    prefs.setString(key, jsonEncode(json));
  }

  @override
  void remove(String key) => prefs.remove(key);
}

/// Defaults to in-memory (see [InMemoryLocalStore]) -- main.dart overrides
/// this with [SharedPreferencesLocalStore] for the real running app.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());
