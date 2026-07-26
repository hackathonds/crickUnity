import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'field_map_models.dart';

class FieldMapState {
  final List<FieldPosition> positions;
  final Map<String, List<FieldPosition>> presets;

  const FieldMapState({required this.positions, this.presets = const {}});

  FieldMapState copyWith({
    List<FieldPosition>? positions,
    Map<String, List<FieldPosition>>? presets,
  }) {
    return FieldMapState(
      positions: positions ?? this.positions,
      presets: presets ?? this.presets,
    );
  }
}

/// DS §11.7: drag tool + phase-preset save/load slots. Team-private (no
/// opponent-visibility concern to enforce here -- this whole screen is
/// only ever reachable by the captain in this debug context).
class FieldMapNotifier extends Notifier<FieldMapState> {
  @override
  FieldMapState build() =>
      FieldMapState(positions: defaultFieldPositions(mockFieldingXI()));

  void moveFielder(String name, double x, double y) {
    state = state.copyWith(
      positions: [
        for (final p in state.positions)
          if (p.fielderName == name) p.copyWith(x: x, y: y) else p,
      ],
    );
  }

  void savePreset(String slotName) {
    state = state.copyWith(
      presets: {...state.presets, slotName: List.of(state.positions)},
    );
  }

  void loadPreset(String slotName) {
    final saved = state.presets[slotName];
    if (saved == null) return;
    state = state.copyWith(positions: List.of(saved));
  }
}

final fieldMapProvider = NotifierProvider<FieldMapNotifier, FieldMapState>(
  FieldMapNotifier.new,
);
