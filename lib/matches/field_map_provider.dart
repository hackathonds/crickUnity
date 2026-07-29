import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
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

  Map<String, dynamic> toJson() => {
    'positions': positions.map((p) => p.toJson()).toList(),
    'presets': presets.map(
      (k, v) => MapEntry(k, v.map((p) => p.toJson()).toList()),
    ),
  };

  factory FieldMapState.fromJson(Map<String, dynamic> json) {
    return FieldMapState(
      positions: [
        for (final p in (json['positions'] as List? ?? const []))
          FieldPosition.fromJson(p as Map<String, dynamic>),
      ],
      presets: {
        for (final entry
            in (json['presets'] as Map<String, dynamic>? ?? const {}).entries)
          entry.key: [
            for (final p in (entry.value as List))
              FieldPosition.fromJson(p as Map<String, dynamic>),
          ],
      },
    );
  }
}

/// DS §11.7: drag tool + phase-preset save/load slots. Team-private (no
/// opponent-visibility concern to enforce here -- this whole screen is
/// only ever reachable by the captain in this debug context).
class FieldMapNotifier extends PersistedNotifier<FieldMapState> {
  @override
  String get persistenceKey => 'field_map_v1';

  @override
  FieldMapState seed() =>
      FieldMapState(positions: defaultFieldPositions(mockFieldingXI()));

  @override
  Map<String, dynamic> toJson(FieldMapState value) => value.toJson();

  @override
  FieldMapState fromJson(Map<String, dynamic> json) =>
      FieldMapState.fromJson(json);

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
