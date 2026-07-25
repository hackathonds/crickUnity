import 'package:flutter/material.dart';

import '../components/app_match_card.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 1/12): [AppMatchCard], [AppLiveMatchCard],
/// [AppTournamentCard].
class MatchCardsScreen extends StatefulWidget {
  const MatchCardsScreen({super.key});

  @override
  State<MatchCardsScreen> createState() => _MatchCardsScreenState();
}

class _MatchCardsScreenState extends State<MatchCardsScreen> {
  AppAvailabilityStatus? _availability = AppAvailabilityStatus.yes;
  String? _keyMoment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Match-context cards (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Match Card — response needed, swipe to share/pin'),
            AppMatchCard(
              teamAName: 'Titans',
              teamBName: 'Strikers',
              format: 'T20',
              dateGroundLine: 'Sun 7:00 AM · Green Park (2.4 km)',
              weatherSummary: '10% rain',
              squadLockCaption: 'Squad locks in 2h',
              statusRail: AppMatchStatusRail.responseNeeded,
              availability: _availability,
              onAvailabilityChanged: (v) => setState(() => _availability = v),
              onTap: () {},
              onShare: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Shared'))),
              onPin: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Pinned'))),
            ),
            label('Live Match Card — tap for Live view, long-press to mute'),
            AppLiveMatchCard(
              teamAName: 'Titans',
              teamBName: 'Strikers',
              scoreLine: '142/3 (14.2)',
              chasingLine: 'Need 47 off 34',
              keyMoment: _keyMoment,
              onTap: () => setState(
                () => _keyMoment = _keyMoment == null
                    ? 'WICKET · Sharma 34'
                    : null,
              ),
              onMute: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Muted'))),
            ),
            label('Tournament Card — sanctioned, registration closing soon'),
            AppTournamentCard(
              name: 'Green Park Premier League',
              sanctioned: true,
              teamsCountDatesEntryFeeLine: '16 teams · 12-20 Aug · ₹2,000',
              registrationCloses: DateTime.now().add(const Duration(hours: 30)),
              onRegister: () {},
            ),
            label('Tournament Card — registered, my-team position'),
            const AppTournamentCard(
              name: 'City T10 Bash',
              teamsCountDatesEntryFeeLine: '8 teams · 5-6 Sep · ₹1,000',
              myTeamPosition: '3rd of 8',
            ),
          ],
        ),
      ),
    );
  }
}
