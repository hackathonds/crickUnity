/// PRD §6.3: "Invite via: search, QR, share-link (expiring 7d,
/// revocable), contact suggestion, 'free-agent board'."
const int inviteLinkExpiryDays = 7;

class TeamInviteLink {
  final String url;
  final DateTime expiresAt;
  final bool revoked;

  const TeamInviteLink({
    required this.url,
    required this.expiresAt,
    this.revoked = false,
  });

  bool isExpired({DateTime Function() now = DateTime.now}) =>
      revoked || !now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
    'url': url,
    'expiresAt': expiresAt.toIso8601String(),
    'revoked': revoked,
  };

  factory TeamInviteLink.fromJson(Map<String, dynamic> json) {
    return TeamInviteLink(
      url: json['url'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      revoked: json['revoked'] as bool? ?? false,
    );
  }
}

/// Mock link generator -- no backend invite-link service exists yet.
TeamInviteLink generateMockInviteLink(
  String teamName, {
  DateTime Function() now = DateTime.now,
}) {
  final slug = teamName.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  return TeamInviteLink(
    url: 'https://cricunity.app/join/$slug-${now().millisecondsSinceEpoch}',
    expiresAt: now().add(const Duration(days: inviteLinkExpiryDays)),
  );
}

/// PRD §6.3: "Invite card shows role offered ('Join as: Player / WK
/// needed'). Invitee sees team profile + Trust context ... Accept ->
/// joins; Decline (optional reason to captain)." Also PRD §11 pattern:
/// "each shows expiry countdown."
class TeamInviteOffer {
  final String teamName;
  final String roleOffered;
  final DateTime expiresAt;

  const TeamInviteOffer({
    required this.teamName,
    required this.roleOffered,
    required this.expiresAt,
  });

  bool expiringSoon({DateTime Function() now = DateTime.now}) =>
      expiresAt.difference(now()).inHours < 24;
}

/// Mock "people you might invite" list for the Invite sheet's Search
/// tab -- no player search/contacts backend exists yet.
const List<String> mockSuggestedPlayersToInvite = [
  'Priya Nair',
  'Kabir Singh',
  'Ananya Iyer',
];
