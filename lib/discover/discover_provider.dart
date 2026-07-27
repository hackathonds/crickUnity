import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'discover_models.dart';

/// Tip cards link to real coachProvider drills (coach_provider.dart's
/// mock: drill-cover-drive/drill-yorker/drill-slip-catching) rather than
/// invented drill IDs, so [Add drill] genuinely opens something real.
final discoverCardsProvider = Provider<List<DiscoverCard>>((ref) {
  return const [
    DiscoverCard(
      type: DiscoverCardType.tip,
      title: 'Fix your cover drive',
      body:
          'Keep your head still and let the ball come to you -- '
          'most mis-hits come from reaching.',
      linkedDrillId: 'drill-cover-drive',
    ),
    DiscoverCard(
      type: DiscoverCardType.rules,
      title: 'What counts as a no-ball?',
      body:
          'Front-foot overstepping, above-shoulder full tosses, and '
          'more than two fielders behind square on the leg side.',
    ),
    DiscoverCard(
      type: DiscoverCardType.tip,
      title: 'Yorkers under pressure',
      body:
          'Aim for the base of off-stump, not the batter\'s feet -- '
          'consistency beats raw pace at the death.',
      linkedDrillId: 'drill-yorker',
      sponsored: true,
      sponsorName: 'CricGear Co.',
    ),
    DiscoverCard(
      type: DiscoverCardType.news,
      title: 'Monsoon Cup fixtures published',
      body: 'The group stage draw is live -- check your team\'s schedule.',
    ),
    DiscoverCard(
      type: DiscoverCardType.tip,
      title: 'Slip catching basics',
      body: 'Soft hands, watch the bat not the ball\'s flight path off it.',
      linkedDrillId: 'drill-slip-catching',
    ),
  ];
});
