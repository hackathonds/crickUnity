import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_leaderboard_row.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../recognition/leaderboard_models.dart';
import 'sanctioning_models.dart';
import 'sanctioning_provider.dart';

/// DS §11.10: "Association profile: crest header + verified-body chip
/// -> member clubs grid -> sanctioned tournaments list (sanction chip
/// explains on tap) -> official rankings tabs -> circulars feed.
/// Rankings pages reuse Leaderboard components with association
/// scope." No crest/logo upload pipeline exists (flagged, same
/// convention as every other missing-asset gap this session).
class AssociationScreen extends ConsumerWidget {
  final String associationId;

  const AssociationScreen({super.key, required this.associationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(sanctioningProvider);
    final association = state.associations
        .where((a) => a.id == associationId)
        .firstOrNull;

    if (association == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Association')),
        body: const Center(child: Text('Association not found.')),
      );
    }

    final granted = state.grantedFor(associationId);
    final rankings = mockLeaderboard(
      scope: LeaderboardScope.association,
      metric: LeaderboardMetric.runs,
      window: LeaderboardWindow.season,
    );

    return Scaffold(
      appBar: AppBar(title: Text(association.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.shield_outlined, color: colors.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(association.name, style: AppTypography.h2),
              if (association.verifiedBody) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.verified, size: 18, color: colors.verified),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Member clubs',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final club in association.memberClubNames)
                Chip(label: Text(club)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Sanctioned tournaments',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (granted.isEmpty)
            Text(
              'No sanctioned tournaments yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final request in granted)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.tournamentName,
                        style: AppTypography.body,
                      ),
                    ),
                    GestureDetector(
                      key: ValueKey('sanctionChip_${request.id}'),
                      onTap: () => _showSanctionExplainer(context, request),
                      child: AppTagChip(
                        label: sanctionStatusLabels[request.status]!,
                        variant: AppTagChipVariant.verified,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Official rankings (association scope)',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 320,
            child: AppLeaderboardList(
              rows: [
                for (var i = 0; i < rankings.length; i++)
                  AppLeaderboardRowData(
                    rank: i + 1,
                    name: rankings[i].name,
                    teamCaption: rankings[i].teamCaption,
                    metric: '${rankings[i].metricValue}',
                    movement: rankings[i].movement == LeaderboardMovement.up
                        ? AppLeaderboardMovement.up
                        : rankings[i].movement == LeaderboardMovement.down
                        ? AppLeaderboardMovement.down
                        : null,
                    movementValue: rankings[i].movementValue,
                  ),
              ],
              myIndex: rankings.indexWhere(
                (r) => r.name == leaderboardViewerName,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Circulars', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final circular in association.circulars)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                circular,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  void _showSanctionExplainer(BuildContext context, SanctionRequest request) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${request.tournamentName} -- ${sanctionStatusLabels[request.status]}',
        ),
        content: Text(
          request.status == SanctionStatus.revoked
              ? 'Sanction revoked. Reason: ${request.revokedReason ?? "no reason given"}'
              : 'This tournament is sanctioned by ${request.associationName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
