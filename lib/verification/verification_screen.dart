import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'verification_models.dart';
import 'verification_provider.dart';

/// PRD §17: "Verification: blue-tick verification for notable figures/
/// organizations (document-based, Admin-reviewed); green verified-record
/// tick for Ground/Academy listings (ownership proof)."
class VerificationRequestScreen extends ConsumerStatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  ConsumerState<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState
    extends ConsumerState<VerificationRequestScreen> {
  VerificationMarkType _markType = VerificationMarkType.blueTick;
  final _entityController = TextEditingController();
  final _justificationController = TextEditingController();
  bool _documentAttached = false;

  @override
  void dispose() {
    _entityController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _entityController.text.trim().isNotEmpty &&
      _justificationController.text.trim().isNotEmpty &&
      _documentAttached;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final myRequests = ref
        .watch(verificationProvider)
        .requests
        .where((r) => r.requesterName == composerViewerName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Request verification')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Mark type',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final type in VerificationMarkType.values)
                ChoiceChip(
                  key: ValueKey('markTypeChip_${type.name}'),
                  label: Text(verificationMarkTypeLabels[type]!),
                  selected: _markType == type,
                  onSelected: (_) => setState(() => _markType = type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const ValueKey('verificationEntityField'),
            controller: _entityController,
            decoration: const InputDecoration(
              labelText: 'Entity/name to verify',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('verificationJustificationField'),
            controller: _justificationController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Why should this be verified?',
            ),
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
            key: const ValueKey('documentAttachedCheckbox'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _documentAttached,
            onChanged: (v) => setState(() => _documentAttached = v ?? false),
            title: Text(
              _markType == VerificationMarkType.greenVerifiedRecord
                  ? 'Ownership proof attached'
                  : 'Supporting document attached',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const ValueKey('submitVerificationRequestButton'),
            onPressed: _canSubmit
                ? () {
                    ref
                        .read(verificationProvider.notifier)
                        .submitRequest(
                          requesterName: composerViewerName,
                          markType: _markType,
                          entityName: _entityController.text.trim(),
                          justification: _justificationController.text.trim(),
                          documentAttached: _documentAttached,
                        );
                    _entityController.clear();
                    _justificationController.clear();
                    setState(() => _documentAttached = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Submitted -- pending Admin review'),
                      ),
                    );
                  }
                : null,
            child: const Text('Submit for Admin review'),
          ),
          if (myRequests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'My requests',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final r in myRequests)
              Padding(
                key: ValueKey('myVerificationRequest_${r.id}'),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(r.entityName)),
                    Text(verificationRequestStatusLabels[r.status]!),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// PRD §16 Admin role: reviews and adjudicates -- mirrors the same
/// review-queue pattern already used for conduct reports (E14-03) and
/// general moderation reports (E7-07).
class AdminVerificationQueueScreen extends ConsumerWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(verificationProvider.notifier);
    final pending = ref
        .watch(verificationProvider)
        .requests
        .where((r) => r.status == VerificationRequestStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Verification queue')),
      body: pending.isEmpty
          ? Center(
              child: Text(
                'No pending requests.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final r in pending)
                  Container(
                    key: ValueKey('verificationQueueRow_${r.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.entityName} -- ${verificationMarkTypeLabels[r.markType]}',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          r.justification,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          r.documentAttached
                              ? 'Document attached'
                              : 'No document attached',
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              key: ValueKey('rejectVerificationButton_${r.id}'),
                              onPressed: () => notifier.reject(
                                r.id,
                                adminNote: 'Insufficient evidence',
                              ),
                              child: const Text('Reject'),
                            ),
                            FilledButton(
                              key: ValueKey(
                                'approveVerificationButton_${r.id}',
                              ),
                              onPressed: () => notifier.approve(r.id),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
