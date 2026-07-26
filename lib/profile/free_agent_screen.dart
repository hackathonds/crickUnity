import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../onboarding/profile_wizard_provider.dart';
import '../teams/recruitment_provider.dart';
import 'free_agent_models.dart';
import 'free_agent_provider.dart';

const Map<PrimaryRole, String> _roleLabels = {
  PrimaryRole.batter: 'Batter',
  PrimaryRole.bowler: 'Bowler',
  PrimaryRole.allRounder: 'All-rounder',
  PrimaryRole.wicketKeeper: 'Wicket-keeper',
};

/// PRD §2.2 empty state ("Join as a free agent") / §8.7 (Auction): "Find
/// a Game" flow -- a free-agent profile toggle with availability days
/// and roles offered, browsing team needs, applying straight into the
/// same pipeline Recruitment Board (E3-11) uses, and individual
/// registration into tournament auction pools.
class FreeAgentScreen extends ConsumerWidget {
  final String playerName;

  const FreeAgentScreen({super.key, required this.playerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(freeAgentProvider);
    final notifier = ref.read(freeAgentProvider.notifier);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Game')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Free-agent mode',
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Switch(
                key: const ValueKey('freeAgentModeSwitch'),
                value: state.profile.isFreeAgent,
                onChanged: notifier.setFreeAgent,
              ),
            ],
          ),
          if (!state.profile.isFreeAgent)
            Text(
              'Turn on free-agent mode to browse team needs and register '
              'for tournament auction pools.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          if (state.profile.isFreeAgent) ...[
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Available days'),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final day in Weekday.values)
                  ChoiceChip(
                    key: ValueKey('availableDayChip_${day.name}'),
                    label: Text(weekdayLabels[day]!),
                    selected: state.profile.availableDays.contains(day),
                    onSelected: (_) => notifier.toggleDay(day),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            sectionLabel('Roles you can offer'),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final role in PrimaryRole.values)
                  ChoiceChip(
                    key: ValueKey('rolesOfferedChip_${role.name}'),
                    label: Text(_roleLabels[role]!),
                    selected: state.profile.rolesOffered.contains(role),
                    onSelected: (_) => notifier.toggleRole(role),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Browse team needs'),
            _TeamNeedsList(
              playerName: playerName,
              rolesOffered: state.profile.rolesOffered,
            ),
            const SizedBox(height: AppSpacing.xxl),
            sectionLabel('Tournament auction pools'),
            Text(
              'No real tournament/auction system exists yet -- this is a '
              'self-registration record only.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AuctionPoolSection(registrations: state.auctionRegistrations),
          ],
        ],
      ),
    );
  }
}

class _TeamNeedsList extends ConsumerWidget {
  final String playerName;
  final Set<PrimaryRole> rolesOffered;

  const _TeamNeedsList({required this.playerName, required this.rolesOffered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final recruitmentState = ref.watch(recruitmentBoardProvider);

    if (recruitmentState.listings.isEmpty) {
      return Text(
        'No open listings right now.',
        style: AppTypography.body.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      children: [
        for (final listing in recruitmentState.listings)
          Builder(
            builder: (context) {
              final expired = listing.isExpired();
              final alreadyApplied = recruitmentState.applicants.any(
                (a) =>
                    a.listingId == listing.id && a.applicantName == playerName,
              );
              final matchesRole = rolesOffered.contains(listing.roleNeeded);

              return Container(
                key: ValueKey('teamNeedCard_${listing.id}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(
                    color: matchesRole ? colors.primary : colors.border,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.teamName,
                            style: AppTypography.subtitle.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_roleLabels[listing.roleNeeded]} · '
                            '${listing.dayTime} · ${listing.area}',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      key: ValueKey('freeAgentApplyButton_${listing.id}'),
                      variant: AppButtonVariant.primary,
                      label: alreadyApplied ? 'Applied' : 'Apply',
                      onPressed: (expired || alreadyApplied)
                          ? null
                          : () => ref
                                .read(recruitmentBoardProvider.notifier)
                                .apply(
                                  listingId: listing.id,
                                  applicantName: playerName,
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AuctionPoolSection extends ConsumerStatefulWidget {
  final List<AuctionPoolRegistration> registrations;

  const _AuctionPoolSection({required this.registrations});

  @override
  ConsumerState<_AuctionPoolSection> createState() =>
      _AuctionPoolSectionState();
}

class _AuctionPoolSectionState extends ConsumerState<_AuctionPoolSection> {
  final _tournamentController = TextEditingController();
  final _basePriceController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _tournamentController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final registration in widget.registrations)
          Padding(
            key: ValueKey('auctionRegistration_${registration.tournamentName}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${registration.tournamentName} -- base '
                    '₹${registration.basePriceRupees}',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  key: ValueKey(
                    'withdrawAuctionButton_${registration.tournamentName}',
                  ),
                  variant: AppButtonVariant.tertiary,
                  label: 'Withdraw',
                  onPressed: () => ref
                      .read(freeAgentProvider.notifier)
                      .withdrawFromAuctionPool(registration.tournamentName),
                ),
              ],
            ),
          ),
        AppTextField(
          key: const ValueKey('auctionTournamentField'),
          label: 'Tournament name',
          controller: _tournamentController,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const ValueKey('auctionBasePriceField'),
          label: 'Base price (₹)',
          controller: _basePriceController,
          keyboardType: TextInputType.number,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            key: const ValueKey('auctionRegistrationError'),
            style: AppTypography.caption.copyWith(color: colors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const ValueKey('registerAuctionPoolButton'),
          variant: AppButtonVariant.secondary,
          label: 'Register for auction pool',
          fullWidth: true,
          onPressed: () {
            final result = ref
                .read(freeAgentProvider.notifier)
                .registerForAuctionPool(
                  tournamentName: _tournamentController.text,
                  basePriceRupees: int.tryParse(_basePriceController.text) ?? 0,
                );
            if (result.succeeded) {
              _tournamentController.clear();
              _basePriceController.clear();
              setState(() => _error = null);
            } else {
              setState(() => _error = result.error);
            }
          },
        ),
      ],
    );
  }
}
