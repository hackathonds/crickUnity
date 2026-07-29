/// DS §11.8: "Production kit screen (organizer): overlay theme gallery,
/// lower-third editor (text fields with live preview strip), destination
/// checklist, commentator-assign row."
library;

class LowerThird {
  final String topText;
  final String bottomText;

  const LowerThird({this.topText = '', this.bottomText = ''});

  LowerThird copyWith({String? topText, String? bottomText}) {
    return LowerThird(
      topText: topText ?? this.topText,
      bottomText: bottomText ?? this.bottomText,
    );
  }

  Map<String, dynamic> toJson() => {
    'topText': topText,
    'bottomText': bottomText,
  };

  factory LowerThird.fromJson(Map<String, dynamic> json) {
    return LowerThird(
      topText: json['topText'] as String? ?? '',
      bottomText: json['bottomText'] as String? ?? '',
    );
  }
}

enum StreamDestination { inApp, youtube, facebook }

const Map<StreamDestination, String> streamDestinationLabels = {
  StreamDestination.inApp: 'CricUnity (in-app)',
  StreamDestination.youtube: 'YouTube',
  StreamDestination.facebook: 'Facebook',
};
