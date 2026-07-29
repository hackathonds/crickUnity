import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'production_kit_models.dart';

class ProductionKitState {
  final LowerThird lowerThird;
  final Set<StreamDestination> destinations;

  const ProductionKitState({
    this.lowerThird = const LowerThird(),
    this.destinations = const {StreamDestination.inApp},
  });

  ProductionKitState copyWith({
    LowerThird? lowerThird,
    Set<StreamDestination>? destinations,
  }) {
    return ProductionKitState(
      lowerThird: lowerThird ?? this.lowerThird,
      destinations: destinations ?? this.destinations,
    );
  }

  Map<String, dynamic> toJson() => {
    'lowerThird': lowerThird.toJson(),
    'destinations': [for (final d in destinations) d.name],
  };

  factory ProductionKitState.fromJson(Map<String, dynamic> json) {
    return ProductionKitState(
      lowerThird: LowerThird.fromJson(
        json['lowerThird'] as Map<String, dynamic>,
      ),
      destinations: {
        for (final d in json['destinations'] as List)
          StreamDestination.values.byName(d as String),
      },
    );
  }
}

/// DS §11.8's overlay-theme gallery and commentator-assign row both
/// reuse other stories' real providers (go_live_provider.dart's
/// overlayTheme, officials/commentator_room_provider.dart's assignment
/// flag) rather than duplicating that state here -- this notifier only
/// owns what's genuinely new to the Production Kit: the lower-third
/// text and the destination checklist.
class ProductionKitNotifier extends PersistedNotifier<ProductionKitState> {
  @override
  String get persistenceKey => 'production_kit_v1';

  @override
  ProductionKitState seed() => const ProductionKitState();

  @override
  Map<String, dynamic> toJson(ProductionKitState value) => value.toJson();

  @override
  ProductionKitState fromJson(Map<String, dynamic> json) =>
      ProductionKitState.fromJson(json);

  void setLowerThirdTopText(String value) {
    state = state.copyWith(
      lowerThird: state.lowerThird.copyWith(topText: value),
    );
  }

  void setLowerThirdBottomText(String value) {
    state = state.copyWith(
      lowerThird: state.lowerThird.copyWith(bottomText: value),
    );
  }

  void toggleDestination(StreamDestination destination) {
    final current = {...state.destinations};
    current.contains(destination)
        ? current.remove(destination)
        : current.add(destination);
    state = state.copyWith(destinations: current);
  }
}

final productionKitProvider =
    NotifierProvider<ProductionKitNotifier, ProductionKitState>(
      ProductionKitNotifier.new,
    );
