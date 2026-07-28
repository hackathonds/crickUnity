import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'club_models.dart';
import 'club_provider.dart';

/// PRD §9 (Club Module). See club_models.dart's top-of-file note for
/// the exact quote and the backlog's narrower 4-part scope: members/
/// dues grid, tiers/subscriptions/grace, inter-team scheduler, wall of
/// fame.
class ClubHomeScreen extends ConsumerStatefulWidget {
  const ClubHomeScreen({super.key});

  @override
  ConsumerState<ClubHomeScreen> createState() => _ClubHomeScreenState();
}

class _ClubHomeScreenState extends ConsumerState<ClubHomeScreen> {
  String? _friendlyTeamA;
  String? _friendlyTeamB;
  DateTime? _friendlyDate;
  final _wallOfFameNameController = TextEditingController();
  final _wallOfFameCitationController = TextEditingController();
  TransferDirection _transferDirection = TransferDirection.clubToTeam;
  String? _transferTeamName;
  final _transferAmountController = TextEditingController();

  @override
  void dispose() {
    _wallOfFameNameController.dispose();
    _wallOfFameCitationController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(clubProvider);
    final notifier = ref.read(clubProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(state.club.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              _Tile(
                label: 'Active members',
                value: '${state.activeMembersCount}',
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
              _Tile(
                label: 'Teams',
                value: '${state.club.linkedTeamNames.length}',
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _Tile(
                label: 'Dues outstanding',
                value: '${state.duesOutstandingCount}',
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
              _Tile(
                label: 'Upcoming events',
                value: '${state.club.upcomingEventsCount}',
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
              _Tile(
                label: 'Join requests',
                value: '${state.club.pendingJoinRequests}',
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Members', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final member in state.members)
            _MemberRow(
              key: ValueKey('memberRow_${member.id}'),
              member: member,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Membership tiers', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Renewal reminders at 7d/1d before due (no notification catalog wired yet -- E12-05).',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final tier in state.tiers.values)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${membershipTierTypeLabels[tier.type]} -- ₹${tier.price}/${subscriptionCadenceLabels[tier.cadence]!.toLowerCase()}',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Grace period: ${tier.gracePeriodDays}d -- lapse pauses benefits, never deletes membership data.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  Text(
                    tier.benefits.join(' · '),
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Inter-team friendly scheduler', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final team in state.club.linkedTeamNames)
                ChoiceChip(
                  key: ValueKey('friendlyTeamAChip_$team'),
                  label: Text('$team (A)'),
                  selected: _friendlyTeamA == team,
                  onSelected: (_) => setState(() => _friendlyTeamA = team),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final team in state.club.linkedTeamNames)
                ChoiceChip(
                  key: ValueKey('friendlyTeamBChip_$team'),
                  label: Text('$team (B)'),
                  selected: _friendlyTeamB == team,
                  onSelected: (_) => setState(() => _friendlyTeamB = team),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _friendlyDate = picked);
            },
            child: Text(
              _friendlyDate == null
                  ? 'Pick date'
                  : '${_friendlyDate!.day}/${_friendlyDate!.month}/${_friendlyDate!.year}',
            ),
          ),
          AppButton(
            key: const ValueKey('scheduleFriendlyButton'),
            variant: AppButtonVariant.secondary,
            label: 'Schedule friendly',
            fullWidth: true,
            onPressed:
                _friendlyTeamA == null ||
                    _friendlyTeamB == null ||
                    _friendlyTeamA == _friendlyTeamB ||
                    _friendlyDate == null
                ? null
                : () {
                    notifier.scheduleFriendly(
                      _friendlyTeamA!,
                      _friendlyTeamB!,
                      _friendlyDate!,
                    );
                    setState(() {
                      _friendlyTeamA = null;
                      _friendlyTeamB = null;
                      _friendlyDate = null;
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final friendly in state.friendlies)
            Text(
              '${friendly.teamAName} vs ${friendly.teamBName} -- ${friendly.date.day}/${friendly.date.month}/${friendly.date.year}',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Wall of Fame', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in state.wallOfFame)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '${entry.memberName} -- ${entry.citation}',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          TextField(
            controller: _wallOfFameNameController,
            decoration: const InputDecoration(labelText: 'Member name'),
          ),
          TextField(
            controller: _wallOfFameCitationController,
            decoration: const InputDecoration(labelText: 'Citation'),
          ),
          AppButton(
            key: const ValueKey('addWallOfFameButton'),
            variant: AppButtonVariant.secondary,
            label: 'Add to Wall of Fame',
            fullWidth: true,
            onPressed: () {
              if (_wallOfFameNameController.text.trim().isEmpty) return;
              notifier.addToWallOfFame(
                _wallOfFameNameController.text.trim(),
                _wallOfFameCitationController.text.trim(),
              );
              _wallOfFameNameController.clear();
              _wallOfFameCitationController.clear();
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Club treasury', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Balance: ₹${state.club.treasuryBalance}',
            style: AppTypography.stat.copyWith(color: colors.textPrimary),
          ),
          Text(
            // PRD §2.13: inter-wallet transfers require both
            // treasurers' confirmation. No multi-account system exists
            // to seat a real distinct team-treasurer identity (flagged,
            // same convention as every other cross-party flow this
            // session) -- both confirmations are recorded from the
            // same single account via debug controls below.
            'Inter-wallet transfers require both the club and team treasurer to confirm.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final request in state.transferRequests)
            _TransferRow(
              key: ValueKey('transferRow_${request.id}'),
              request: request,
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('Club -> Team'),
                selected: _transferDirection == TransferDirection.clubToTeam,
                onSelected: (_) => setState(
                  () => _transferDirection = TransferDirection.clubToTeam,
                ),
              ),
              ChoiceChip(
                label: const Text('Team -> Club'),
                selected: _transferDirection == TransferDirection.teamToClub,
                onSelected: (_) => setState(
                  () => _transferDirection = TransferDirection.teamToClub,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final team in state.club.linkedTeamNames)
                ChoiceChip(
                  key: ValueKey('transferTeamChip_$team'),
                  label: Text(team),
                  selected: _transferTeamName == team,
                  onSelected: (_) => setState(() => _transferTeamName = team),
                ),
            ],
          ),
          TextField(
            controller: _transferAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (₹)'),
          ),
          AppButton(
            key: const ValueKey('requestTransferButton'),
            variant: AppButtonVariant.secondary,
            label: 'Request transfer',
            fullWidth: true,
            onPressed: _transferTeamName == null
                ? null
                : () {
                    final amount =
                        int.tryParse(_transferAmountController.text) ?? 0;
                    if (amount <= 0) return;
                    notifier.requestTransfer(
                      _transferDirection,
                      _transferTeamName!,
                      amount,
                    );
                    _transferAmountController.clear();
                    setState(() {});
                  },
          ),
        ],
      ),
    );
  }
}

class _TransferRow extends ConsumerWidget {
  final InterWalletTransferRequest request;
  final AppColors colors;

  const _TransferRow({super.key, required this.request, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(clubProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request.direction == TransferDirection.clubToTeam ? "Club -> ${request.teamName}" : "${request.teamName} -> Club"}: ₹${request.amount}',
            style: AppTypography.body,
          ),
          Text(
            request.completed
                ? 'Completed'
                : 'Club treasurer: ${request.clubTreasurerConfirmed ? "confirmed" : "pending"} · '
                      'Team treasurer: ${request.teamTreasurerConfirmed ? "confirmed" : "pending"}',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (!request.completed)
            Row(
              children: [
                if (!request.clubTreasurerConfirmed)
                  TextButton(
                    onPressed: () =>
                        notifier.confirmAsClubTreasurer(request.id),
                    child: const Text('Confirm as club treasurer'),
                  ),
                if (!request.teamTreasurerConfirmed)
                  TextButton(
                    onPressed: () =>
                        notifier.confirmAsTeamTreasurer(request.id),
                    child: const Text('Confirm as team treasurer'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;

  const _Tile({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            Text(
              value,
              style: AppTypography.stat.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final ClubMember member;
  final AppColors colors;

  const _MemberRow({super.key, required this.member, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = switch (member.duesStatus) {
      DuesStatus.green => AppTagChipVariant.success,
      DuesStatus.amber => AppTagChipVariant.warning,
      DuesStatus.red => AppTagChipVariant.error,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Chip(
                      label: Text(
                        membershipTierTypeLabels[member.tier]!,
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${clubRoleLabels[member.role]} · joined ${member.joinDate.year}',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          AppTagChip(
            label: duesStatusLabels[member.duesStatus]!,
            variant: variant,
          ),
        ],
      ),
    );
  }
}
