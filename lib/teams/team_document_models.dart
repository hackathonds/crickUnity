import 'team_member_models.dart';

/// DS §7 screen 20 (Documents) has no literal anatomy string of its own
/// -- it's grouped under DS §7's "17. Jersey Board / 18. Carpool / 19.
/// Duty Roster / 20. Documents / 21. Kit Inventory -- pattern screens:
/// list + claim/submit sheets" framing. No PRD section covers team
/// document storage at all. Proceeding on the backlog's own concrete
/// summary ("role-based doc uploads") plus that shared "list + submit
/// sheet" pattern already implemented for Jersey Board/Carpool/Duty
/// Roster/Kit Inventory.
const List<TeamMemberRole> documentUploadRoles = [
  TeamMemberRole.owner,
  TeamMemberRole.captain,
  TeamMemberRole.viceCaptain,
  TeamMemberRole.manager,
];

class TeamDocument {
  final String id;
  final String name;
  final String uploaderName;
  final DateTime uploadedAt;

  const TeamDocument({
    required this.id,
    required this.name,
    required this.uploaderName,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'uploaderName': uploaderName,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory TeamDocument.fromJson(Map<String, dynamic> json) {
    return TeamDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      uploaderName: json['uploaderName'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

/// Mock data for the debug demo and tests -- no backend document-storage
/// service exists yet.
List<TeamDocument> mockTeamDocuments({
  DateTime Function() now = DateTime.now,
}) => [
  TeamDocument(
    id: 'doc-1',
    name: 'Team insurance certificate.pdf',
    uploaderName: 'Rohan Kapoor',
    uploadedAt: now().subtract(const Duration(days: 40)),
  ),
  TeamDocument(
    id: 'doc-2',
    name: 'Ground booking permission letter.pdf',
    uploaderName: 'Rohan Kapoor',
    uploadedAt: now().subtract(const Duration(days: 12)),
  ),
];
