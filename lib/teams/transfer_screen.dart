import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'transfer_models.dart';
import 'transfer_provider.dart';

/// PRD §6.26 (Transfers): personal stats travel with the player; the
/// departed team's aggregates freeze at the moment of transfer;
/// rival-team transfers respect the tournament's transfer-window rule
/// and are visible to the organizer; the former captain gets a
/// courtesy notification. No Tournament/organizer module or real
/// player-stats/team-aggregate system exists yet -- this screen models
/// the one rule that's fully specified (window enforcement) and
/// surfaces the rest as confirmation copy rather than real data moves,
/// same honest-gap treatment as other cross-epic stand-ins this
/// session (see transfer_provider.dart's doc comment).
class TransferScreen extends ConsumerStatefulWidget {
  final String playerName;
  final String fromTeamName;

  const TransferScreen({
    super.key,
    required this.playerName,
    required this.fromTeamName,
  });

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _toTeamController = TextEditingController();
  bool _isRivalTransfer = false;
  TransferWindowStatus _windowStatus = TransferWindowStatus.open;
  String? _error;
  TransferRecord? _lastCompleted;

  @override
  void dispose() {
    _toTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(transferProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Leaving ${widget.fromTeamName}',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: const ValueKey('toTeamField'),
            label: 'Destination team',
            controller: _toTeamController,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'This is a rival team in an active tournament',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Switch(
                key: const ValueKey('rivalTransferSwitch'),
                value: _isRivalTransfer,
                onChanged: (value) => setState(() => _isRivalTransfer = value),
              ),
            ],
          ),
          if (_isRivalTransfer) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tournament fixtures already published '
                    '(window locked)',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('windowLockedSwitch'),
                  value:
                      _windowStatus == TransferWindowStatus.lockedPostFixtures,
                  onChanged: (value) => setState(
                    () => _windowStatus = value
                        ? TransferWindowStatus.lockedPostFixtures
                        : TransferWindowStatus.open,
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              key: const ValueKey('transferError'),
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('transferButton'),
            variant: AppButtonVariant.primary,
            label: 'Transfer',
            fullWidth: true,
            onPressed: () {
              final result = ref
                  .read(transferProvider.notifier)
                  .initiateTransfer(
                    playerName: widget.playerName,
                    fromTeamName: widget.fromTeamName,
                    toTeamName: _toTeamController.text,
                    isRivalTransfer: _isRivalTransfer,
                    windowStatus: _windowStatus,
                  );
              if (result.succeeded) {
                setState(() {
                  _error = null;
                  _lastCompleted = state.transfers.firstWhere(
                    (t) => t.id == result.transferId,
                  );
                });
              } else {
                setState(() => _error = result.error);
              }
            },
          ),
          if (_lastCompleted != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              key: const ValueKey('transferConfirmation'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transferred to ${_lastCompleted!.toTeamName}',
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your personal stats travel with you. '
                    "${widget.fromTeamName}'s team aggregates are frozen "
                    'as of today. Your former captain has been sent a '
                    'courtesy notification.'
                    '${_lastCompleted!.isRivalTransfer ? ' This transfer is visible to the tournament organizer.' : ''}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Transfer history',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.transfers.isEmpty)
            Text(
              'No transfers yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final transfer in state.transfers)
              Padding(
                key: ValueKey('transferHistoryRow_${transfer.id}'),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  '${transfer.fromTeamName} -> ${transfer.toTeamName}',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
        ],
      ),
    );
  }
}
