/// PRD §16 (Search): "Advanced Search: filter sheet per type — Player:
/// role, batting/bowling style, city+radius, age band, rating range,
/// Trust band, 'free agent', availability day. Team: city, format,
/// recruiting-now, activity level, follower count. Tournament: city,
/// dates, format, ball, entry fee range, registration open, organizer
/// score. Ground: distance, price range, pitch type, facilities
/// (multi), rating, available-on {date/slot}. Club: city, membership
/// open, teams count. Post: by author, tag, hashtag, attached-object
/// type, date. Expense (scoped inside module) ... Message (scoped
/// inside chat/messenger) ..." Expense and Message are explicitly
/// "scoped inside module" per PRD's own wording -- out of this global-
/// search story, not a gap.
///
/// Several PRD-listed fields have no backing data anywhere in this
/// codebase (no player batting-style/city/rating/Trust-band/
/// availability model; no team directory beyond names; no club
/// city/membership-open/teams-count field) -- those filter sheets
/// still expose every PRD-named field (so the shape matches the spec)
/// but fields with no real data are disabled with an inline note,
/// rather than faked against nothing.
library;

import '../onboarding/profile_wizard_provider.dart' show PrimaryRole;
import '../grounds/ground_models.dart';
import '../social/feed_models.dart' show AttachedObjectType;
import '../tournaments/tournament_models.dart';

class PlayerFilter {
  final PrimaryRole? role;

  const PlayerFilter({this.role});

  bool get isEmpty => role == null;

  Map<String, dynamic> toJson() => {'role': role?.name};

  factory PlayerFilter.fromJson(Map<String, dynamic> json) {
    return PlayerFilter(
      role: json['role'] != null
          ? PrimaryRole.values.byName(json['role'] as String)
          : null,
    );
  }
}

class TournamentFilter {
  final String? city;
  final TournamentFormat? format;
  final TournamentBallType? ballType;
  final int? maxEntryFee;
  final bool registrationOpenOnly;

  const TournamentFilter({
    this.city,
    this.format,
    this.ballType,
    this.maxEntryFee,
    this.registrationOpenOnly = false,
  });

  bool get isEmpty =>
      city == null &&
      format == null &&
      ballType == null &&
      maxEntryFee == null &&
      !registrationOpenOnly;

  Map<String, dynamic> toJson() => {
    'city': city,
    'format': format?.name,
    'ballType': ballType?.name,
    'maxEntryFee': maxEntryFee,
    'registrationOpenOnly': registrationOpenOnly,
  };

  factory TournamentFilter.fromJson(Map<String, dynamic> json) {
    return TournamentFilter(
      city: json['city'] as String?,
      format: json['format'] != null
          ? TournamentFormat.values.byName(json['format'] as String)
          : null,
      ballType: json['ballType'] != null
          ? TournamentBallType.values.byName(json['ballType'] as String)
          : null,
      maxEntryFee: json['maxEntryFee'] as int?,
      registrationOpenOnly: json['registrationOpenOnly'] as bool? ?? false,
    );
  }
}

class GroundFilter {
  final double? maxDistanceKm;
  final int? maxPrice;
  final PitchType? pitchType;
  final Set<Facility> facilities;
  final double? minRating;

  const GroundFilter({
    this.maxDistanceKm,
    this.maxPrice,
    this.pitchType,
    this.facilities = const {},
    this.minRating,
  });

  bool get isEmpty =>
      maxDistanceKm == null &&
      maxPrice == null &&
      pitchType == null &&
      facilities.isEmpty &&
      minRating == null;

  Map<String, dynamic> toJson() => {
    'maxDistanceKm': maxDistanceKm,
    'maxPrice': maxPrice,
    'pitchType': pitchType?.name,
    'facilities': [for (final f in facilities) f.name],
    'minRating': minRating,
  };

  factory GroundFilter.fromJson(Map<String, dynamic> json) {
    return GroundFilter(
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble(),
      maxPrice: json['maxPrice'] as int?,
      pitchType: json['pitchType'] != null
          ? PitchType.values.byName(json['pitchType'] as String)
          : null,
      facilities: {
        for (final f in json['facilities'] as List)
          Facility.values.byName(f as String),
      },
      minRating: (json['minRating'] as num?)?.toDouble(),
    );
  }
}

class PostFilter {
  final String? author;
  final String? hashtag;
  final AttachedObjectType? attachedObjectType;
  final DateTime? afterDate;

  const PostFilter({
    this.author,
    this.hashtag,
    this.attachedObjectType,
    this.afterDate,
  });

  bool get isEmpty =>
      author == null &&
      hashtag == null &&
      attachedObjectType == null &&
      afterDate == null;

  Map<String, dynamic> toJson() => {
    'author': author,
    'hashtag': hashtag,
    'attachedObjectType': attachedObjectType?.name,
    'afterDate': afterDate?.toIso8601String(),
  };

  factory PostFilter.fromJson(Map<String, dynamic> json) {
    return PostFilter(
      author: json['author'] as String?,
      hashtag: json['hashtag'] as String?,
      attachedObjectType: json['attachedObjectType'] != null
          ? AttachedObjectType.values.byName(
              json['attachedObjectType'] as String,
            )
          : null,
      afterDate: json['afterDate'] != null
          ? DateTime.parse(json['afterDate'] as String)
          : null,
    );
  }
}

class SavedFilterSet {
  final String id;
  final String name;
  final PlayerFilter? playerFilter;
  final TournamentFilter? tournamentFilter;
  final GroundFilter? groundFilter;
  final PostFilter? postFilter;

  const SavedFilterSet({
    required this.id,
    required this.name,
    this.playerFilter,
    this.tournamentFilter,
    this.groundFilter,
    this.postFilter,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'playerFilter': playerFilter?.toJson(),
    'tournamentFilter': tournamentFilter?.toJson(),
    'groundFilter': groundFilter?.toJson(),
    'postFilter': postFilter?.toJson(),
  };

  factory SavedFilterSet.fromJson(Map<String, dynamic> json) {
    return SavedFilterSet(
      id: json['id'] as String,
      name: json['name'] as String,
      playerFilter: json['playerFilter'] != null
          ? PlayerFilter.fromJson(json['playerFilter'] as Map<String, dynamic>)
          : null,
      tournamentFilter: json['tournamentFilter'] != null
          ? TournamentFilter.fromJson(
              json['tournamentFilter'] as Map<String, dynamic>,
            )
          : null,
      groundFilter: json['groundFilter'] != null
          ? GroundFilter.fromJson(json['groundFilter'] as Map<String, dynamic>)
          : null,
      postFilter: json['postFilter'] != null
          ? PostFilter.fromJson(json['postFilter'] as Map<String, dynamic>)
          : null,
    );
  }
}
