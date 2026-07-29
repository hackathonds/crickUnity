import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'availability_models.dart';

class AvailabilityNotifier extends PersistedNotifier<AvailabilityState> {
  @override
  String get persistenceKey => 'availability_v1';

  @override
  AvailabilityState seed() => const AvailabilityState();

  @override
  Map<String, dynamic> toJson(AvailabilityState value) => value.toJson();

  @override
  AvailabilityState fromJson(Map<String, dynamic> json) =>
      AvailabilityState.fromJson(json);

  void setAvailable() =>
      state = const AvailabilityState(status: AvailabilityStatus.available);

  void setBusyUntil(DateTime date) => state = AvailabilityState(
    status: AvailabilityStatus.busy,
    busyUntil: date,
  );

  /// PRD §5.16: "Injured — injured pauses streak penalties." The
  /// detailed injury log (type/date/notes) is DS §11.16 / PRD backlog
  /// E16-05, a separate future story -- this just flips the availability
  /// flag itself.
  void setInjured() =>
      state = const AvailabilityState(status: AvailabilityStatus.injured);
}

final availabilityProvider =
    NotifierProvider<AvailabilityNotifier, AvailabilityState>(
      AvailabilityNotifier.new,
    );
