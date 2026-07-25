import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app currently considers itself online. No real connectivity
/// detection exists yet — this is debug-toggle-only until a real
/// connectivity story wires it up to the platform.
final isOnlineProvider = StateProvider<bool>((ref) => true);
