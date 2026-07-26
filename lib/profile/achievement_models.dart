import 'package:flutter/material.dart';

/// PRD §13.3 "Badges taxonomy: Performance · Consistency · Leadership ·
/// Service (scorer/umpire/volunteer) · Community · Collector (grounds/
/// tournaments) · Special (founder, season-exclusive)."
enum BadgeCategory {
  performance,
  consistency,
  leadership,
  service,
  community,
  collector,
  special,
}

const Map<BadgeCategory, String> badgeCategoryLabels = {
  BadgeCategory.performance: 'Performance',
  BadgeCategory.consistency: 'Consistency',
  BadgeCategory.leadership: 'Leadership',
  BadgeCategory.service: 'Service',
  BadgeCategory.community: 'Community',
  BadgeCategory.collector: 'Collector',
  BadgeCategory.special: 'Special',
};

/// PRD §18: "each badge page shows earn criteria, rarity %, holders you
/// know." §5.6: "badge wall ..., filterable by category, each with earn
/// date + the triggering match link" (the match link itself has no
/// backend yet -- out of scope, same as other match-data gaps this
/// session).
class AchievementBadge {
  final String name;
  final Color color;
  final BadgeCategory category;
  final bool earned;
  final String criteria;
  final int rarityPercent;
  final List<String> friendsWhoHold;
  final String? earnDateAndProvenance;

  const AchievementBadge({
    required this.name,
    required this.color,
    required this.category,
    required this.earned,
    required this.criteria,
    required this.rarityPercent,
    this.friendsWhoHold = const [],
    this.earnDateAndProvenance,
  });
}

/// Mock catalog for the debug demo and tests -- no backend achievements
/// system exists yet.
List<AchievementBadge> mockAchievementBadges() => const [
  AchievementBadge(
    name: 'Century Club',
    color: Colors.deepOrange,
    category: BadgeCategory.performance,
    earned: true,
    criteria: 'Score 100+ runs in a single innings.',
    rarityPercent: 4,
    friendsWhoHold: ['Arjun Rao', 'Priya Nair'],
    earnDateAndProvenance: 'Earned 12 Jun 2026 · vs Strikers',
  ),
  AchievementBadge(
    name: 'Hat-trick Hero',
    color: Colors.deepPurple,
    category: BadgeCategory.performance,
    earned: false,
    criteria: 'Take 3 wickets in 3 consecutive balls.',
    rarityPercent: 1,
  ),
  AchievementBadge(
    name: 'Iron Player',
    color: Colors.blueGrey,
    category: BadgeCategory.consistency,
    earned: true,
    criteria: 'Play 26 consecutive weeks with at least one match.',
    rarityPercent: 8,
    friendsWhoHold: ['Kabir Singh'],
    earnDateAndProvenance: 'Earned 3 Mar 2026',
  ),
  AchievementBadge(
    name: 'Captain Fantastic',
    color: Colors.indigo,
    category: BadgeCategory.leadership,
    earned: false,
    criteria: 'Win 20 matches as captain.',
    rarityPercent: 6,
  ),
  AchievementBadge(
    name: 'Fair Play',
    color: Colors.teal,
    category: BadgeCategory.leadership,
    earned: true,
    criteria: 'Maintain an Exemplary sportsmanship streak for a season.',
    rarityPercent: 12,
    earnDateAndProvenance: 'Earned 30 Sep 2025',
  ),
  AchievementBadge(
    name: 'Whistle-blower',
    color: Colors.brown,
    category: BadgeCategory.service,
    earned: false,
    criteria: 'Umpire 25 verified matches.',
    rarityPercent: 3,
  ),
  AchievementBadge(
    name: 'Scorer Supreme',
    color: Colors.cyan,
    category: BadgeCategory.service,
    earned: false,
    criteria: 'Score 50 matches with zero disputes.',
    rarityPercent: 2,
  ),
  AchievementBadge(
    name: 'Crowd Favorite',
    color: Colors.pink,
    category: BadgeCategory.community,
    earned: true,
    criteria: 'Receive 500 Props across all your posts.',
    rarityPercent: 15,
    friendsWhoHold: ['Ananya Iyer', 'Priya Nair', 'Arjun Rao'],
    earnDateAndProvenance: 'Earned 18 Jan 2026',
  ),
  AchievementBadge(
    name: 'Ground Collector',
    color: Colors.green,
    category: BadgeCategory.collector,
    earned: false,
    criteria: 'Play at 25 different grounds.',
    rarityPercent: 5,
  ),
  AchievementBadge(
    name: 'Founder',
    color: Colors.amber,
    category: BadgeCategory.special,
    earned: true,
    criteria: 'Joined CricUnity in its first season.',
    rarityPercent: 1,
    earnDateAndProvenance: 'Earned 1 Apr 2025',
  ),
];
