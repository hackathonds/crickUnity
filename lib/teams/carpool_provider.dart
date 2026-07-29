import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'carpool_models.dart';

class CarpoolState {
  final List<CarpoolRide> rides;

  const CarpoolState({this.rides = const []});

  CarpoolState copyWith({List<CarpoolRide>? rides}) {
    return CarpoolState(rides: rides ?? this.rides);
  }

  Map<String, dynamic> toJson() => {
    'rides': rides.map((r) => r.toJson()).toList(),
  };

  factory CarpoolState.fromJson(Map<String, dynamic> json) {
    return CarpoolState(
      rides: [
        for (final r in (json['rides'] as List? ?? const []))
          CarpoolRide.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

class CarpoolNotifier extends PersistedNotifier<CarpoolState> {
  @override
  String get persistenceKey => 'carpool_v1';

  @override
  CarpoolState seed() => CarpoolState(rides: mockCarpoolRides());

  @override
  Map<String, dynamic> toJson(CarpoolState value) => value.toJson();

  @override
  CarpoolState fromJson(Map<String, dynamic> json) =>
      CarpoolState.fromJson(json);

  /// Returns null on success; a human-readable denial reason otherwise.
  String? joinRide(String rideId, String riderName) {
    final ride = state.rides.firstWhere((r) => r.id == rideId);
    if (ride.riders.contains(riderName)) {
      return 'Already joined this ride.';
    }
    if (ride.isFull) {
      return 'This ride is full.';
    }
    state = state.copyWith(
      rides: [
        for (final r in state.rides)
          if (r.id == rideId)
            r.copyWith(riders: [...r.riders, riderName])
          else
            r,
      ],
    );
    return null;
  }

  void leaveRide(String rideId, String riderName) {
    state = state.copyWith(
      rides: [
        for (final r in state.rides)
          if (r.id == rideId)
            r.copyWith(riders: r.riders.where((n) => n != riderName).toList())
          else
            r,
      ],
    );
  }
}

final carpoolProvider = NotifierProvider<CarpoolNotifier, CarpoolState>(
  CarpoolNotifier.new,
);
