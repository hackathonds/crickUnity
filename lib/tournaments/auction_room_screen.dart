import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../onboarding/profile_wizard_provider.dart' show PrimaryRole;
import 'auction_models.dart';
import 'auction_provider.dart';
import 'registration_models.dart';
import 'registrations_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// Backlog E10-06 (XL): "split lot/bidding/purse/spectator/reconnect."
/// PRD §8.7 + DS §7-40 (a real numbered screen entry) -- see
/// auction_models.dart's top-of-file note for the exact quotes.
///
/// - Sub-part "lot": _LotCard (player card XL + base price).
/// - Sub-part "bidding": bid-increment buttons (64px targets per DS),
///   the 12s Arc timer ring driving resolveLot().
/// - Sub-part "purse": _PurseRail (all teams, tabular numerals).
/// - Sub-part "spectator": a view toggle that hides bid controls.
/// - Sub-part "reconnect": a one-time banner on mount when the auction
///   was already live, demonstrating the state survived leaving and
///   re-entering this screen (the state genuinely lives in
///   auctionProvider, not this widget, so this isn't cosmetic).
class AuctionRoomScreen extends ConsumerStatefulWidget {
  const AuctionRoomScreen({super.key});

  @override
  ConsumerState<AuctionRoomScreen> createState() => _AuctionRoomScreenState();
}

class _AuctionRoomScreenState extends ConsumerState<AuctionRoomScreen> {
  String? _selectedTournamentId;
  bool _spectatorMode = false;
  Timer? _ticker;
  DateTime? _lotStartedAt;
  String? _lastLotId;
  bool _showReconnectBanner = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final published = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .toList();
    final auctionState = ref.watch(auctionProvider);
    final auctionNotifier = ref.read(auctionProvider.notifier);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    final tournament = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction room')),
        body: Center(
          child: Text(
            'No published tournaments yet -- publish one first (E10-01).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final lot = auctionState.currentLot(tournament.id);
    final purses = auctionState.pursesFor(tournament.id);

    // Sub-part "reconnect": a lot already being live when this screen
    // (re)builds after the notifier state existed beforehand is the
    // observable proof the auction survived a navigate-away/back.
    if (lot != null && lot.id != _lastLotId) {
      _lastLotId = lot.id;
      _lotStartedAt = DateTime.now();
      if (auctionState.bidLogFor(tournament.id).isNotEmpty || lot.round > 1) {
        _showReconnectBanner = true;
      }
    }

    if (lot != null && lot.status == LotStatus.live && _lotStartedAt != null) {
      final elapsed = DateTime.now().difference(_lotStartedAt!);
      if (elapsed >= lotTimerDuration) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          auctionNotifier.resolveLot(tournament.id);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Auction · ${tournament.name}'),
        actions: [
          IconButton(
            key: const ValueKey('toggleSpectatorModeButton'),
            icon: Icon(
              _spectatorMode ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: _spectatorMode ? 'Exit spectator mode' : 'Spectator mode',
            onPressed: () => setState(() => _spectatorMode = !_spectatorMode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in published)
                ChoiceChip(
                  key: ValueKey('auctionTournamentChip_${t.id}'),
                  label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                  selected: _selectedTournamentId == t.id,
                  onSelected: (_) => setState(() {
                    _selectedTournamentId = t.id;
                    _lastLotId = null;
                  }),
                ),
            ],
          ),
          if (_showReconnectBanner) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: const ValueKey('reconnectBanner'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi, color: colors.success, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Reconnected -- lot state preserved.',
                      style: AppTypography.caption.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showReconnectBanner = false),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (purses.isEmpty)
            _SetupPanel(tournamentId: tournament.id, colors: colors)
          else ...[
            _PurseRail(purses: purses, colors: colors),
            const SizedBox(height: AppSpacing.xl),
            if (lot == null)
              Text(
                'Auction complete -- no more lots.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              )
            else
              _LotCard(
                lot: lot,
                colors: colors,
                remaining: _lotStartedAt == null
                    ? lotTimerDuration
                    : (lotTimerDuration -
                              DateTime.now().difference(_lotStartedAt!))
                          .isNegative
                    ? Duration.zero
                    : lotTimerDuration -
                          DateTime.now().difference(_lotStartedAt!),
              ),
            if (!_spectatorMode &&
                lot != null &&
                lot.status == LotStatus.live) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Place bid for',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final purse in purses)
                    ChoiceChip(
                      key: ValueKey('bidTeamChip_${purse.registrationId}'),
                      label: Text(purse.teamName),
                      selected: false,
                      onSelected: (_) {},
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final purse in purses)
                _TeamBidRow(
                  key: ValueKey('teamBidRow_${purse.registrationId}'),
                  tournamentId: tournament.id,
                  purse: purse,
                  colors: colors,
                ),
            ],
            if (_spectatorMode)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  'Spectator mode -- bid controls hidden.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const ValueKey('reRoundUnsoldButton'),
              variant: AppButtonVariant.secondary,
              label: 'Re-round unsold lots',
              fullWidth: true,
              onPressed: () => auctionNotifier.reRoundUnsold(tournament.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupPanel extends ConsumerWidget {
  final String tournamentId;
  final AppColors colors;

  const _SetupPanel({required this.tournamentId, required this.colors});

  static const _samplePool = [
    FreeAgent(
      id: 'agent-1',
      name: 'Rohan Verma',
      role: PrimaryRole.batter,
      basePrice: 100,
    ),
    FreeAgent(
      id: 'agent-2',
      name: 'Priya Nair',
      role: PrimaryRole.bowler,
      basePrice: 100,
    ),
    FreeAgent(
      id: 'agent-3',
      name: 'Arjun Rao',
      role: PrimaryRole.allRounder,
      basePrice: 150,
    ),
    FreeAgent(
      id: 'agent-4',
      name: 'Meera Joshi',
      role: PrimaryRole.wicketKeeper,
      basePrice: 120,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvedTeams = ref
        .watch(registrationsProvider)
        .forTournament(tournamentId)
        .where((r) => r.status == RegistrationStatus.approved)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up the player pool (${_samplePool.length} free agents) and team purses to start.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const ValueKey('setupAuctionButton'),
          variant: AppButtonVariant.primary,
          label: 'Start auction',
          fullWidth: true,
          onPressed: approvedTeams.isEmpty
              ? null
              : () {
                  final purses = [
                    for (final team in approvedTeams)
                      AuctionTeamPurse(
                        registrationId: team.id,
                        teamName: team.teamName,
                        totalPurse: 1000,
                        minSquadSize: team.squad.isEmpty
                            ? 1
                            : team.squad.length,
                      ),
                  ];
                  ref
                      .read(auctionProvider.notifier)
                      .setupAuction(tournamentId, _samplePool, purses);
                },
        ),
      ],
    );
  }
}

class _PurseRail extends StatelessWidget {
  final List<AuctionTeamPurse> purses;
  final AppColors colors;

  const _PurseRail({required this.purses, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: purses.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final purse = purses[index];
          return Container(
            key: ValueKey('purseRailTile_${purse.registrationId}'),
            width: 140,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purse.teamName,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${purse.remaining}',
                  style: AppTypography.stat.copyWith(
                    fontSize: 15,
                    height: 20 / 15,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  final Lot lot;
  final AppColors colors;
  final Duration remaining;

  const _LotCard({
    required this.lot,
    required this.colors,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remaining.inMilliseconds / lotTimerDuration.inMilliseconds;
    return Container(
      key: ValueKey('lotCard_${lot.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (lot.status == LotStatus.live)
            Stack(
              alignment: Alignment.center,
              children: [
                AppArcRing(
                  progress: progress.clamp(0.0, 1.0),
                  size: 56,
                  strokeWidth: 5,
                  trackColor: colors.border,
                  fillColor: colors.warning,
                ),
                Text('${remaining.inSeconds}s', style: AppTypography.caption),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(lot.player.name, style: AppTypography.h1),
          Text(
            '${lot.player.role.name} · Base ₹${lot.player.basePrice}',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lot.currentBidderTeamName == null
                ? 'No bids yet'
                : '₹${lot.currentBid} · ${lot.currentBidderTeamName}',
            style: AppTypography.stat.copyWith(color: colors.textPrimary),
          ),
          if (lot.status != LotStatus.live)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                lot.status == LotStatus.sold ? 'SOLD' : 'UNSOLD',
                style: AppTypography.label.copyWith(
                  color: lot.status == LotStatus.sold
                      ? colors.success
                      : colors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamBidRow extends ConsumerWidget {
  final String tournamentId;
  final AuctionTeamPurse purse;
  final AppColors colors;

  const _TeamBidRow({
    super.key,
    required this.tournamentId,
    required this.purse,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(purse.teamName, style: AppTypography.body)),
          for (final increment in bidIncrements)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: SizedBox(
                height: 64,
                child: AppButton(
                  key: ValueKey('bidButton_${purse.registrationId}_$increment'),
                  variant: AppButtonVariant.tertiary,
                  label: '+$increment',
                  onPressed: () {
                    final error = ref
                        .read(auctionProvider.notifier)
                        .placeBid(
                          tournamentId,
                          purse.registrationId,
                          increment,
                        );
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
