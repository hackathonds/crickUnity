import '../onboarding/profile_wizard_provider.dart' show PrimaryRole;

/// DS §7 screen 14 (Selection Board, captain/VC): "Two panes: Available
/// pool ... / XI list (bottom, drag-target slots 56 numbered 1–11
/// +12th)." 12 total slots (11 playing + 12th man).
const int xiSlotCount = 12;

class PlayerCandidate {
  final String name;
  final PrimaryRole role;

  const PlayerCandidate({required this.name, required this.role});
}

/// PRD §7.5: "post-lock changes = 'replacement' flow requiring opponent
/// captain acknowledgment, logged."
class ReplacementRequest {
  final String id;
  final String outgoingName;
  final String incomingName;
  final String reason;
  final bool acknowledged;

  const ReplacementRequest({
    required this.id,
    required this.outgoingName,
    required this.incomingName,
    required this.reason,
    this.acknowledged = false,
  });
}

/// Mock squad pool for the debug demo and tests -- no backend Match/
/// Create-match flow exists yet (that's E4-01, a separate future epic);
/// this story's own scope is the selection mechanics themselves, using a
/// self-contained mock pool rather than a real match's actual roster.
List<PlayerCandidate> mockSelectionPool() => const [
  PlayerCandidate(name: 'Rohan Verma', role: PrimaryRole.batter),
  PlayerCandidate(name: 'Arjun Rao', role: PrimaryRole.allRounder),
  PlayerCandidate(name: 'Priya Nair', role: PrimaryRole.bowler),
  PlayerCandidate(name: 'Kabir Singh', role: PrimaryRole.batter),
  PlayerCandidate(name: 'Ananya Iyer', role: PrimaryRole.bowler),
  PlayerCandidate(name: 'Farhan Ali', role: PrimaryRole.allRounder),
  PlayerCandidate(name: 'Vikram Shah', role: PrimaryRole.batter),
  PlayerCandidate(name: 'Meera Joshi', role: PrimaryRole.wicketKeeper),
  PlayerCandidate(name: 'Suresh Patel', role: PrimaryRole.bowler),
  PlayerCandidate(name: 'Kunal Mehta', role: PrimaryRole.batter),
  PlayerCandidate(name: 'Aditya Kumar', role: PrimaryRole.bowler),
  PlayerCandidate(name: 'Rahul Deshmukh', role: PrimaryRole.allRounder),
  PlayerCandidate(name: 'Sanjay Gupta', role: PrimaryRole.batter),
  PlayerCandidate(name: 'Imran Khan', role: PrimaryRole.bowler),
];
