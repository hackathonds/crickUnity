/// PRD §2.17 (Super Admin): "configure coin economy rates, XP curves,
/// fee policies, feature flags per region; view platform analytics;
/// manage Admin accounts; final appeal authority." Restrictions:
/// "Dual-control for economy changes (second Super Admin co-sign);
/// public changelog for policy changes affecting users' coins/fees."
///
/// Backlog cites "G.14" for this story, but DS §11.1's traceability
/// matrix maps G.14 to the Sandbox tutorial (already built, E16-07,
/// DS §11.18) -- a mismatched citation, not a real pointer to Admin/
/// governance content. DS §7.10 screen 69 only specs the Admin queue
/// console (E16-11); no DS screen exists for this Super-Admin economy
/// console. Built from PRD §2.17 and §13.1 alone.
library;

/// PRD §13.1's canonical earning table, reused verbatim (not
/// synthesized) as the tunable rate set this console edits.
class EarningRule {
  final String action;
  final int coins;
  final int xp;
  final String note;

  const EarningRule({
    required this.action,
    required this.coins,
    required this.xp,
    this.note = '',
  });

  EarningRule copyWith({int? coins, int? xp}) {
    return EarningRule(
      action: action,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      note: note,
    );
  }
}

const List<EarningRule> canonicalEarningRules = [
  EarningRule(
    action: 'Play a verified match',
    coins: 20,
    xp: 50,
    note: 'Bench/12th: 10/25',
  ),
  EarningRule(action: 'Win bonus', coins: 10, xp: 20, note: 'Team-wide'),
  EarningRule(
    action: 'Fifty / Century',
    coins: 25,
    xp: 60,
    note: 'Per innings',
  ),
  EarningRule(action: '3W / 5W', coins: 25, xp: 60),
  EarningRule(action: 'MVP', coins: 40, xp: 100),
  EarningRule(
    action: 'Practice attendance',
    coins: 8,
    xp: 15,
    note: 'Cap 4/week',
  ),
  EarningRule(
    action: 'Score a match (scorer)',
    coins: 30,
    xp: 60,
    note: '+10 if zero disputes',
  ),
  EarningRule(action: 'Umpire a match', coins: 30, xp: 60),
  EarningRule(
    action: 'Organize a completed match',
    coins: 15,
    xp: 30,
    note: 'Captain bonus',
  ),
  EarningRule(action: 'Daily login', coins: 2, xp: 2, note: 'See streaks'),
];

/// PRD §2.17 restriction: "Dual-control for economy changes (second
/// Super Admin co-sign)." A proposed rule edit sits here, inert, until
/// a *different* Super Admin co-signs it.
class PendingRateChange {
  final String id;
  final String ruleAction;
  final int currentCoins;
  final int currentXp;
  final int proposedCoins;
  final int proposedXp;
  final String proposedBy;
  final DateTime proposedAt;

  const PendingRateChange({
    required this.id,
    required this.ruleAction,
    required this.currentCoins,
    required this.currentXp,
    required this.proposedCoins,
    required this.proposedXp,
    required this.proposedBy,
    required this.proposedAt,
  });
}

/// No PRD/DS fee schedule exists -- flagged judgment call naming the
/// platform fee surfaces plausible for this app (gig-board booking,
/// marketplace listings), same convention as other unspecified-detail
/// flags this session.
class FeePolicy {
  final String name;
  final double percent;

  const FeePolicy({required this.name, required this.percent});

  FeePolicy copyWith({double? percent}) {
    return FeePolicy(name: name, percent: percent ?? this.percent);
  }
}

const List<FeePolicy> defaultFeePolicies = [
  FeePolicy(name: 'Gig board booking fee', percent: 5),
  FeePolicy(name: 'Marketplace listing fee', percent: 8),
];

/// Same dual-control restriction as [PendingRateChange], applied to
/// fee-percent edits rather than earning rules.
class PendingFeeChange {
  final String id;
  final String feeName;
  final double currentPercent;
  final double proposedPercent;
  final String proposedBy;
  final DateTime proposedAt;

  const PendingFeeChange({
    required this.id,
    required this.feeName,
    required this.currentPercent,
    required this.proposedPercent,
    required this.proposedBy,
    required this.proposedAt,
  });
}

/// Reuses the only two real ground cities in this app's data
/// (grounds_provider.dart) as the region set -- not an invented list.
const List<String> platformRegions = ['Delhi', 'Mumbai'];

class FeatureFlag {
  final String key;
  final String label;
  final Set<String> enabledRegions;

  const FeatureFlag({
    required this.key,
    required this.label,
    this.enabledRegions = const {},
  });

  FeatureFlag copyWith({Set<String>? enabledRegions}) {
    return FeatureFlag(
      key: key,
      label: label,
      enabledRegions: enabledRegions ?? this.enabledRegions,
    );
  }
}

const List<FeatureFlag> defaultFeatureFlags = [
  FeatureFlag(key: 'streaming', label: 'Go-Live streaming'),
  FeatureFlag(key: 'marketplace', label: 'Gear Exchange marketplace'),
  FeatureFlag(key: 'luckLayer', label: 'Scratch/spin/lucky-draw luck layer'),
];

/// PRD §2.17 restriction: "public changelog for policy changes
/// affecting users' coins/fees." Auto-appended whenever a co-signed
/// rate or fee change lands -- this is the public-facing surface, not
/// an internal audit log (that's the Admin console's, E16-11).
class ChangelogEntry {
  final String id;
  final String title;
  final String description;
  final DateTime publishedAt;

  const ChangelogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.publishedAt,
  });
}

/// "Platform status banner" is named in the backlog line but not
/// specified in PRD/DS beyond that phrase -- flagged judgment call for
/// a minimal 3-level status model.
enum PlatformStatusLevel { operational, degraded, maintenance }

const Map<PlatformStatusLevel, String> platformStatusLabels = {
  PlatformStatusLevel.operational: 'All systems operational',
  PlatformStatusLevel.degraded: 'Degraded performance',
  PlatformStatusLevel.maintenance: 'Scheduled maintenance',
};
