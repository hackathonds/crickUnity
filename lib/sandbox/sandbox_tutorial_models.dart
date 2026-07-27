/// DS §11.18 (Micro-additions): "Sandbox tutorial: first scoring-console
/// open offers 'Practice with a sample match' -- console loads with
/// SANDBOX watermark chip and coach-mark sequence per control; exit
/// anytime; zero stat/XP writes (explicit banner)."
///
/// Backlog cites this story (E16-07) against "G.14" -- no Appendix G
/// exists anywhere in the frozen PRD, flagged rather than guessed at.
/// The backlog's "Help" and "feature-request board" halves have no
/// PRD/DS text anywhere naming them (not even a DS mention, unlike
/// Commentator/Knowledge Hub/Gear, which at least had one) -- flagged
/// as ungrounded rather than invented; only the sandbox tutorial is
/// built here.
///
/// This is a standalone practice surface, not the real Live Scoring
/// console wired to a sandbox flag -- keeping it fully separate from
/// the real scoring providers is what makes "zero stat/XP writes"
/// genuinely true rather than a banner promising something the shared
/// global state could still violate.
library;

class CoachMarkStep {
  final String targetLabel;
  final String description;

  const CoachMarkStep({required this.targetLabel, required this.description});
}

const List<CoachMarkStep> sandboxCoachMarks = [
  CoachMarkStep(
    targetLabel: 'Run buttons',
    description: 'Tap 0/1/2/3/4/6 to record runs off each ball.',
  ),
  CoachMarkStep(
    targetLabel: 'Wicket',
    description: 'Tap Wicket to record a dismissal.',
  ),
  CoachMarkStep(
    targetLabel: 'Extras',
    description: 'Wd/Nb/B/Lb for wides, no-balls, byes and leg-byes.',
  ),
  CoachMarkStep(
    targetLabel: 'Undo',
    description: 'Made a mistake? Undo removes the last ball.',
  ),
];
