import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// DS §11.8's overlay-theme gallery and commentator-assign row both
/// reuse other stories' real providers (go_live_provider.dart's
/// overlayTheme, officials/commentator_room_provider.dart's assignment
/// flag) rather than duplicating that state here -- this notifier only
/// owns what's genuinely new to the Production Kit: the lower-third
/// text and the destination checklist.
class ProductionKitNotifier extends Notifier<ProductionKitState> {
  @override
  ProductionKitState build() => const ProductionKitState();

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
