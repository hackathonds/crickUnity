import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'association_screen.dart';
import 'sanctioning_models.dart';
import 'sanctioning_provider.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

/// DS §11.10: "Sanction request (organizer side): from Tournament
/// Console -- request card -> status tracker (Requested/Review/Granted
/// with public-reason on revoke)."
class SanctionRequestScreen extends ConsumerStatefulWidget {
  const SanctionRequestScreen({super.key});

  @override
  ConsumerState<SanctionRequestScreen> createState() =>
      _SanctionRequestScreenState();
}

class _SanctionRequestScreenState extends ConsumerState<SanctionRequestScreen> {
  String? _selectedTournamentId;
  String? _selectedAssociationId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final published = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .toList();
    final sanctioningState = ref.watch(sanctioningProvider);
    final sanctioningNotifier = ref.read(sanctioningProvider.notifier);

    if (_selectedTournamentId == null && published.isNotEmpty) {
      _selectedTournamentId = published.first.id;
    }
    if (_selectedAssociationId == null &&
        sanctioningState.associations.isNotEmpty) {
      _selectedAssociationId = sanctioningState.associations.first.id;
    }
    final tournament = published
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;
    final association = sanctioningState.associations
        .where((a) => a.id == _selectedAssociationId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Sanction requests')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (published.isEmpty)
            Text(
              'No published tournaments yet -- publish one first (E10-01).',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else ...[
            Text(
              'Tournament',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final t in published)
                  ChoiceChip(
                    key: ValueKey('sanctionTournamentChip_${t.id}'),
                    label: Text(t.name.isEmpty ? '(unnamed)' : t.name),
                    selected: _selectedTournamentId == t.id,
                    onSelected: (_) =>
                        setState(() => _selectedTournamentId = t.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Association',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final a in sanctioningState.associations)
                  ChoiceChip(
                    key: ValueKey('sanctionAssociationChip_${a.id}'),
                    label: Text(a.name),
                    selected: _selectedAssociationId == a.id,
                    onSelected: (_) =>
                        setState(() => _selectedAssociationId = a.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('requestSanctionButton'),
              variant: AppButtonVariant.primary,
              label: 'Request sanction',
              fullWidth: true,
              onPressed: tournament == null || association == null
                  ? null
                  : () => sanctioningNotifier.requestSanction(
                      tournament.id,
                      tournament.name,
                      association.id,
                      association.name,
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Requests', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            for (final request in sanctioningState.requests)
              _RequestCard(
                key: ValueKey('sanctionRequestCard_${request.id}'),
                request: request,
                colors: colors,
              ),
          ],
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final SanctionRequest request;
  final AppColors colors;

  const _RequestCard({super.key, required this.request, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sanctioningProvider.notifier);
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.tournamentName} -> ${request.associationName}',
                  style: AppTypography.body,
                ),
              ),
              AppTagChip(
                label: sanctionStatusLabels[request.status]!,
                variant: request.status == SanctionStatus.granted
                    ? AppTagChipVariant.success
                    : (request.status == SanctionStatus.revoked
                          ? AppTagChipVariant.error
                          : AppTagChipVariant.warning),
              ),
            ],
          ),
          // DS §11.10: "status tracker (Requested/Review/Granted...)."
          Row(
            children: [
              for (final status in [
                SanctionStatus.requested,
                SanctionStatus.review,
                SanctionStatus.granted,
              ])
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: 2,
                    ),
                    color:
                        status.index <= request.status.index &&
                            request.status != SanctionStatus.revoked
                        ? colors.success
                        : colors.border,
                  ),
                ),
            ],
          ),
          if (request.status == SanctionStatus.revoked)
            Text(
              'Revoked -- ${request.revokedReason}',
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (request.status != SanctionStatus.granted &&
                  request.status != SanctionStatus.revoked)
                TextButton(
                  key: ValueKey('advanceSanctionButton_${request.id}'),
                  onPressed: () => notifier.advanceStatus(request.id),
                  child: const Text('Advance status'),
                ),
              if (request.status == SanctionStatus.granted)
                TextButton(
                  key: ValueKey('revokeSanctionButton_${request.id}'),
                  onPressed: () => _showRevokeSheet(context, ref),
                  child: const Text('Revoke'),
                ),
              if (request.status == SanctionStatus.granted)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AssociationScreen(
                        associationId: request.associationId,
                      ),
                    ),
                  ),
                  child: const Text('View association'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRevokeSheet(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Revoke sanction -- public reason', style: AppTypography.h2),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Public reason (required)',
                ),
                onChanged: (_) => setSheetState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                variant: AppButtonVariant.destructive,
                label: 'Confirm revoke',
                fullWidth: true,
                onPressed: reasonController.text.trim().isEmpty
                    ? null
                    : () {
                        ref
                            .read(sanctioningProvider.notifier)
                            .revoke(request.id, reasonController.text.trim());
                        Navigator.of(context).pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
