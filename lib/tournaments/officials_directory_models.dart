/// AC amendment #11 (PRD §2.6, misfiled backlog citation "G.5"):
/// "tournament official filters honor tier + certification." No
/// organizer-facing officials directory existed anywhere in this
/// codebase -- officials_console_screen.dart is one official's own
/// single-person dashboard, and gig_board_screen.dart lists gigs (jobs)
/// from an official's perspective, not people an organizer can browse.
/// This is a new, small directory; its roster is a flagged mock
/// dataset (same convention as every other multi-person dataset this
/// session, e.g. mockCareerMatches) since no real officials-registry
/// backend exists.
library;

import '../officials/gig_board_models.dart' show OfficialRole;
import '../officials/officials_console_models.dart' show CredentialTier;

class DirectoryOfficial {
  final String name;
  final OfficialRole role;
  final CredentialTier tier;
  final Set<String> certifiedTrackIds;
  final double averageRating;

  const DirectoryOfficial({
    required this.name,
    required this.role,
    required this.tier,
    this.certifiedTrackIds = const {},
    required this.averageRating,
  });
}

const Map<String, String> certificationTrackLabels = {
  'cert-scorer-advanced': 'Advanced Scorer',
  'cert-umpire-laws': 'Laws of Cricket',
  'cert-umpire-advanced': 'Advanced Umpiring',
};

List<DirectoryOfficial> mockOfficialsDirectory() => const [
  DirectoryOfficial(
    name: 'Farhan Ali',
    role: OfficialRole.scorer,
    tier: CredentialTier.gold,
    certifiedTrackIds: {'cert-scorer-advanced'},
    averageRating: 4.7,
  ),
  DirectoryOfficial(
    name: 'Kabir Singh',
    role: OfficialRole.scorer,
    tier: CredentialTier.bronze,
    averageRating: 4.1,
  ),
  DirectoryOfficial(
    name: 'Ananya Iyer',
    role: OfficialRole.umpire,
    tier: CredentialTier.platinum,
    certifiedTrackIds: {'cert-umpire-laws', 'cert-umpire-advanced'},
    averageRating: 4.9,
  ),
  DirectoryOfficial(
    name: 'Rohan Verma',
    role: OfficialRole.umpire,
    tier: CredentialTier.silver,
    certifiedTrackIds: {'cert-umpire-laws'},
    averageRating: 4.3,
  ),
];

class OfficialsDirectoryFilters {
  final OfficialRole? role;
  final CredentialTier? minTier;
  final String? requiredCertificationId;

  const OfficialsDirectoryFilters({
    this.role,
    this.minTier,
    this.requiredCertificationId,
  });

  OfficialsDirectoryFilters copyWith({
    OfficialRole? role,
    bool clearRole = false,
    CredentialTier? minTier,
    bool clearMinTier = false,
    String? requiredCertificationId,
    bool clearCertification = false,
  }) {
    return OfficialsDirectoryFilters(
      role: clearRole ? null : (role ?? this.role),
      minTier: clearMinTier ? null : (minTier ?? this.minTier),
      requiredCertificationId: clearCertification
          ? null
          : (requiredCertificationId ?? this.requiredCertificationId),
    );
  }

  bool matches(DirectoryOfficial official) {
    if (role != null && official.role != role) return false;
    if (minTier != null && official.tier.index < minTier!.index) return false;
    if (requiredCertificationId != null &&
        !official.certifiedTrackIds.contains(requiredCertificationId)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'role': role?.name,
    'minTier': minTier?.name,
    'requiredCertificationId': requiredCertificationId,
  };

  factory OfficialsDirectoryFilters.fromJson(Map<String, dynamic> json) {
    return OfficialsDirectoryFilters(
      role: json['role'] != null
          ? OfficialRole.values.byName(json['role'] as String)
          : null,
      minTier: json['minTier'] != null
          ? CredentialTier.values.byName(json['minTier'] as String)
          : null,
      requiredCertificationId: json['requiredCertificationId'] as String?,
    );
  }
}
