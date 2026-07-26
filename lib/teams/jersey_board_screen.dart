import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'jersey_board_models.dart';
import 'jersey_board_provider.dart';

/// PRD §6.12: "Jersey board: design image, size-collection form (members
/// submit size/name/number; conflicts on number flagged with
/// claim-by-seniority suggestion), order status tracker ... Members see
/// own size submission; Manager sees full sheet."
class JerseyBoardScreen extends ConsumerWidget {
  final String viewerName;
  final bool isManager;

  const JerseyBoardScreen({
    super.key,
    required this.viewerName,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(jerseyBoardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Jersey board')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Order status',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  jerseyOrderStatusLabels[state.orderStatus]!,
                  key: const ValueKey('jerseyOrderStatusLabel'),
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isManager)
                AppButton(
                  key: const ValueKey('advanceOrderStatusButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Advance',
                  onPressed: state.orderStatus == JerseyOrderStatus.distributed
                      ? null
                      : () => ref
                            .read(jerseyBoardProvider.notifier)
                            .advanceOrderStatus(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (isManager)
            _ManagerSheet(state: state)
          else
            _MemberOwnSubmission(viewerName: viewerName, state: state),
        ],
      ),
    );
  }
}

class _MemberOwnSubmission extends ConsumerStatefulWidget {
  final String viewerName;
  final JerseyBoardState state;

  const _MemberOwnSubmission({required this.viewerName, required this.state});

  @override
  ConsumerState<_MemberOwnSubmission> createState() =>
      _MemberOwnSubmissionState();
}

class _MemberOwnSubmissionState extends ConsumerState<_MemberOwnSubmission> {
  late final _sizeController = TextEditingController(
    text: _existing?.size ?? '',
  );
  late final _nameController = TextEditingController(
    text: _existing?.nameOnJersey ?? '',
  );
  late final _numberController = TextEditingController(
    text: _existing?.number?.toString() ?? '',
  );

  JerseySizeSubmission? get _existing {
    for (final submission in widget.state.submissions) {
      if (submission.memberName == widget.viewerName) return submission;
    }
    return null;
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      key: const ValueKey('memberOwnSubmissionSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your size submission',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const ValueKey('jerseySizeField'),
          label: 'Size',
          controller: _sizeController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const ValueKey('jerseyNameField'),
          label: 'Name on jersey',
          controller: _nameController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const ValueKey('jerseyNumberField'),
          label: 'Number',
          controller: _numberController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: const ValueKey('jerseySubmitButton'),
          variant: AppButtonVariant.primary,
          label: 'Submit',
          fullWidth: true,
          onPressed: () => ref
              .read(jerseyBoardProvider.notifier)
              .submitSize(
                memberName: widget.viewerName,
                size: _sizeController.text,
                nameOnJersey: _nameController.text,
                number: int.tryParse(_numberController.text),
              ),
        ),
      ],
    );
  }
}

class _ManagerSheet extends ConsumerWidget {
  final JerseyBoardState state;

  const _ManagerSheet({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(jerseyBoardProvider.notifier);
    final pricePerMember = state.pricePerMember();

    return Column(
      key: const ValueKey('managerSheetSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pricePerMember != null)
          Text(
            '₹$pricePerMember per member (₹${state.totalPriceRupees} total)',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Full sheet',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final submission in state.submissions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              '${submission.memberName} -- ${submission.size}, '
              '"${submission.nameOnJersey}"'
              '${submission.number != null ? ', #${submission.number}' : ' (no number yet)'}',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
        if (state.numberConflicts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Number conflicts',
            style: AppTypography.label.copyWith(color: colors.warning),
          ),
          for (final entry in state.numberConflicts.entries)
            Padding(
              key: ValueKey('numberConflict_${entry.key}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${entry.key}: ${entry.value.map((s) => s.memberName).join(', ')}',
                      style: AppTypography.caption.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ),
                  AppButton(
                    key: ValueKey('resolveConflict_${entry.key}'),
                    variant: AppButtonVariant.tertiary,
                    label: 'Resolve by seniority',
                    onPressed: () =>
                        notifier.resolveConflictBySeniority(entry.key),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
