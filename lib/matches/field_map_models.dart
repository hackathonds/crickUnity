/// DS §11.7: "Field map tool (captain, from Match overflow): drag 11
/// fielder tokens 32 on oval; phase presets save slots; team-private
/// badge."
class FieldPosition {
  final String fielderName;

  /// Normalized 0.0-1.0 position within the oval's bounding box.
  final double x;
  final double y;

  const FieldPosition({
    required this.fielderName,
    required this.x,
    required this.y,
  });

  FieldPosition copyWith({double? x, double? y}) {
    return FieldPosition(
      fielderName: fielderName,
      x: (x ?? this.x).clamp(0.0, 1.0),
      y: (y ?? this.y).clamp(0.0, 1.0),
    );
  }
}

/// PRD/DS give no fixed fielding-phase names -- these three (Powerplay/
/// Middle overs/Death overs) are the standard limited-overs phases and
/// match the "phase presets" wording literally without inventing an
/// arbitrary-naming system nothing else in the app has.
const List<String> fieldMapPresetSlots = [
  'Powerplay',
  'Middle overs',
  'Death overs',
];

/// Mock fielding XI for the debug demo -- no real Selection Board
/// (E3-08) hookup exists yet.
List<String> mockFieldingXI() => const [
  'Deepak Sharma',
  'Rahul Deshmukh',
  'Sanjay Gupta',
  'Imran Khan',
  'Vikas Nair',
  'Rohan Verma',
  'Kabir Singh',
  'Arjun Rao',
  'Priya Nair',
  'Ananya Iyer',
  'Farhan Ali',
];

/// A conventional starting field (wicketkeeper behind the stumps,
/// slips, a scattering of infield/outfield positions) -- just a
/// reasonable default layout, not tied to any specific format's rules.
List<FieldPosition> defaultFieldPositions(List<String> names) {
  const offsets = [
    (0.5, 0.92), // keeper
    (0.58, 0.85), // first slip
    (0.66, 0.8), // gully
    (0.8, 0.65), // point
    (0.85, 0.45), // cover
    (0.75, 0.2), // mid off
    (0.5, 0.08), // bowler's end / mid on-ish
    (0.25, 0.2), // mid on
    (0.15, 0.45), // midwicket
    (0.2, 0.65), // square leg
    (0.35, 0.85), // fine leg
  ];
  return [
    for (var i = 0; i < names.length && i < offsets.length; i++)
      FieldPosition(fielderName: names[i], x: offsets[i].$1, y: offsets[i].$2),
  ];
}
