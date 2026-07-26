import 'package:flutter/material.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/theme/app_theme.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'season_summary_models.dart';
import 'team_member_models.dart';

/// PRD §6.29 gives no explicit presenter role beyond "Captain can
/// present" -- Owner/VC included per the standard team-management set
/// used throughout Epic E3 (Owner has "everything Captain has" per
/// §2.9).
const Set<TeamMemberRole> seasonSummaryPresenterRoles = {
  TeamMemberRole.owner,
  TeamMemberRole.captain,
  TeamMemberRole.viceCaptain,
};

/// PRD §6.19/6.29, DS §7 screen 22 (Season Summary / Awards Ceremony
/// mode): "Wrap cards vertical; [Present] switches to full-screen
/// sequential reveal (tap-advance, Clash display, Theme-2 styling),
/// money slide auto-excluded from public share." The [Present] action
/// is structurally absent for viewers outside
/// [seasonSummaryPresenterRoles], matching the privileged-action gating
/// pattern used throughout Epic E3.
class SeasonSummaryScreen extends StatelessWidget {
  final TeamMemberRole viewerRole;
  final SeasonSummaryData data;

  const SeasonSummaryScreen({
    super.key,
    required this.viewerRole,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final canPresent = seasonSummaryPresenterRoles.contains(viewerRole);

    if (data.matchesPlayed < seasonSummaryMinMatches) {
      return Scaffold(
        appBar: AppBar(title: const Text('Season summary')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              key: const ValueKey('seasonSummaryInsufficientData'),
              "Not enough matches played yet for a season summary -- "
              'play at least $seasonSummaryMinMatches to unlock one.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    final milestones = detectMilestones(
      matchesPlayed: data.matchesPlayed,
      winsCount: data.winsCount,
      championshipsWon: data.championshipsWon,
    );
    final wrapCards = data.toWrapCards();

    return Scaffold(
      appBar: AppBar(title: const Text('Season summary')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (milestones.isNotEmpty) ...[
            Text(
              'Milestones',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final milestone in milestones)
              Container(
                key: ValueKey('milestoneCard_${milestone.type.name}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.coin.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestoneTitles[milestone.type]!,
                      style: AppTypography.subtitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Commemorative badge awarded to the then-roster',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          Text(
            'Season wrap',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final card in wrapCards) _WrapCardTile(card: card),
          if (canPresent) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('presentCeremonyButton'),
              variant: AppButtonVariant.primary,
              label: 'Present',
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CeremonyView(cards: wrapCards),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('previewPublicShareButton'),
              variant: AppButtonVariant.secondary,
              label: 'Preview public share',
              fullWidth: true,
              onPressed: () => _showPublicSharePreview(context, wrapCards),
            ),
          ],
        ],
      ),
    );
  }

  void _showPublicSharePreview(BuildContext context, List<WrapCard> cards) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Public share preview',
      contentBuilder: (context) => _PublicSharePreviewContent(cards: cards),
    );
  }
}

class _WrapCardTile extends StatelessWidget {
  final WrapCard card;

  const _WrapCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: ValueKey('wrapCard_${card.type.name}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            card.body,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// DS: "money slide auto-excluded from public share." A plain list
/// preview showing exactly what a shared version would contain --
/// filtering happens once here rather than the sharing action needing
/// its own duplicate rule.
class _PublicSharePreviewContent extends StatelessWidget {
  final List<WrapCard> cards;

  const _PublicSharePreviewContent({required this.cards});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final publicCards = cards.where((c) => !c.isMoneyCard).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The money summary card never appears in a public share.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final card in publicCards)
            Padding(
              key: ValueKey('publicShareCard_${card.type.name}'),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                card.title,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// DS: "[Present] switches to full-screen sequential reveal (tap-advance,
/// Clash display, Theme-2 styling)." Theme-2 is forced here regardless of
/// the viewer's own theme selection, same as any other DS-mandated fixed
/// theme override.
class _CeremonyView extends StatefulWidget {
  final List<WrapCard> cards;

  const _CeremonyView({required this.cards});

  @override
  State<_CeremonyView> createState() => _CeremonyViewState();
}

class _CeremonyViewState extends State<_CeremonyView> {
  int _index = 0;

  void _advance() {
    if (_index == widget.cards.length - 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themes[AppThemeId.theme2]!,
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).extension<AppColors>()!;
          final card = widget.cards[_index];

          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              backgroundColor: colors.surface,
              leading: IconButton(
                key: const ValueKey('closeCeremonyButton'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: GestureDetector(
              key: const ValueKey('ceremonyTapAdvance'),
              behavior: HitTestBehavior.opaque,
              onTap: _advance,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    key: ValueKey('ceremonyCard_${card.type.name}'),
                    children: [
                      Text(
                        card.title,
                        style: AppTypography.display.copyWith(
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        card.body,
                        style: AppTypography.subtitle.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
