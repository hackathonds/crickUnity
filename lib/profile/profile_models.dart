import 'package:flutter/material.dart';

/// PRD §5: "Viewer-relative rendering: the same profile renders
/// differently for Self, Teammate/Friend, Follower, Public, and Blocked."
enum ViewerRelation { self, teammate, follower, public, blocked }

/// PRD §5.20 Profile Visibility presets.
enum ProfileVisibility { public, community, private }

class PinnedBadge {
  final String name;
  final Color color;

  const PinnedBadge({required this.name, required this.color});
}

class FavoriteItem {
  final String label;

  const FavoriteItem(this.label);
}

class EndorsementTag {
  final String label;
  final int count;

  const EndorsementTag({required this.label, required this.count});
}

/// PRD §5.14 Recent Form: "Last-5 string ... with W/L color underline."
enum FormResult { win, loss, other }

class RecentFormEntry {
  final String label;
  final FormResult result;

  const RecentFormEntry({required this.label, required this.result});
}

/// The sticky stat header strip (DS §7 screen 4-5: "M · Runs · Wkts ·
/// Rating tnum"). [verified] drives Pillar 2's visual treatment (engraved
/// solid vs lighter/dashed) -- the full Verified/Unverified stats *tab* is
/// E2-03, out of scope here.
class ProfileHeaderStats {
  final int matches;
  final int runs;
  final int wickets;
  final int rating;
  final bool verified;

  const ProfileHeaderStats({
    required this.matches,
    required this.runs,
    required this.wickets,
    required this.rating,
    this.verified = true,
  });
}

/// A plain data holder for everything the profile screen renders. No
/// backend/data model exists yet (Teams/Matches/Endorsements are later
/// epics) -- callers (today, only the debug demo) supply mock values;
/// real fetching is each future story's own concern.
class PlayerProfile {
  final String name;
  final String city;
  final String bio;
  final List<String> roleChips;
  final bool isVerifiedAccount;
  final double levelProgress;
  final ImageProvider? avatarImage;
  final Color coverColor;
  final List<PinnedBadge> pinnedBadges;
  final ProfileHeaderStats headerStats;
  final List<RecentFormEntry> recentForm;
  final List<FavoriteItem> favoriteTeams;
  final List<EndorsementTag> endorsements;
  final bool isMinor;
  final ProfileVisibility visibility;

  const PlayerProfile({
    required this.name,
    required this.city,
    required this.bio,
    required this.roleChips,
    required this.headerStats,
    this.isVerifiedAccount = true,
    this.levelProgress = 0.4,
    this.avatarImage,
    this.coverColor = const Color(0xFF123B2A),
    this.pinnedBadges = const [],
    this.recentForm = const [],
    this.favoriteTeams = const [],
    this.endorsements = const [],
    this.isMinor = false,
    this.visibility = ProfileVisibility.public,
  });
}

/// Mock data for the debug demo and tests -- not a real fetched profile.
PlayerProfile mockPlayerProfile() => const PlayerProfile(
  name: 'Rohan Verma',
  city: 'Pune',
  bio: 'Middle-order finisher. Lions CC #7.',
  roleChips: ['Player', 'Captain @ Lions CC'],
  headerStats: ProfileHeaderStats(
    matches: 42,
    runs: 1180,
    wickets: 6,
    rating: 74,
  ),
  pinnedBadges: [
    PinnedBadge(name: 'Century Club', color: Colors.deepOrange),
    PinnedBadge(name: 'Hat-trick Hero', color: Colors.deepPurple),
    PinnedBadge(name: 'MVP', color: Colors.teal),
  ],
  recentForm: [
    RecentFormEntry(label: '45*', result: FormResult.win),
    RecentFormEntry(label: '12', result: FormResult.loss),
    RecentFormEntry(label: '3/20', result: FormResult.win),
    RecentFormEntry(label: 'DNB', result: FormResult.other),
    RecentFormEntry(label: '61', result: FormResult.win),
  ],
  favoriteTeams: [FavoriteItem('Lions CC'), FavoriteItem('Mumbai Indians')],
  endorsements: [
    EndorsementTag(label: 'Fielding', count: 12),
    EndorsementTag(label: 'Death overs', count: 7),
  ],
);
