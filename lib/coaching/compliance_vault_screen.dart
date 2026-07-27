import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'compliance_models.dart';
import 'compliance_provider.dart';

/// Backlog E11-04: cert/first-aid expiries, signed-status matrix
/// blocking registration. See compliance_models.dart's top-of-file
/// note for the flagged phantom "G.13" citation.
class ComplianceVaultScreen extends ConsumerStatefulWidget {
  const ComplianceVaultScreen({super.key});

  @override
  ConsumerState<ComplianceVaultScreen> createState() =>
      _ComplianceVaultScreenState();
}

class _ComplianceVaultScreenState extends ConsumerState<ComplianceVaultScreen> {
  final _coachNameController = TextEditingController(text: 'Coach Ramesh');
  ComplianceDocType _newDocType = ComplianceDocType.coachingCertification;
  DateTime? _newExpiryDate;

  @override
  void dispose() {
    _coachNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(complianceProvider);
    final notifier = ref.read(complianceProvider.notifier);
    final coachName = _coachNameController.text.trim();
    final matrix = coachName.isEmpty
        ? <ComplianceDocType, ComplianceDocument?>{}
        : state.matrixFor(coachName);
    final isCompliant =
        coachName.isNotEmpty &&
        state.isCoachCompliant(coachName, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Compliance vault')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            key: const ValueKey('complianceCoachNameField'),
            controller: _coachNameController,
            decoration: const InputDecoration(labelText: 'Coach name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (coachName.isNotEmpty)
            AppTagChip(
              label: isCompliant
                  ? 'Compliant -- can be assigned'
                  : 'Not compliant -- assignment blocked',
              variant: isCompliant
                  ? AppTagChipVariant.success
                  : AppTagChipVariant.error,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Signed-status matrix', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final type in requiredComplianceDocs)
            _MatrixRow(
              key: ValueKey('matrixRow_${type.name}'),
              docType: type,
              document: matrix[type],
              colors: colors,
              onSign: matrix[type] == null
                  ? null
                  : () => notifier.signDocument(matrix[type]!.id),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Add / renew document', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final type in ComplianceDocType.values)
                ChoiceChip(
                  key: ValueKey('newDocTypeChip_${type.name}'),
                  label: Text(complianceDocTypeLabels[type]!),
                  selected: _newDocType == type,
                  onSelected: (_) => setState(() => _newDocType = type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) setState(() => _newExpiryDate = picked);
            },
            child: Text(
              _newExpiryDate == null
                  ? 'Pick expiry date'
                  : '${_newExpiryDate!.day}/${_newExpiryDate!.month}/${_newExpiryDate!.year}',
            ),
          ),
          AppButton(
            key: const ValueKey('addComplianceDocButton'),
            variant: AppButtonVariant.secondary,
            label: 'Add document',
            fullWidth: true,
            onPressed: coachName.isEmpty || _newExpiryDate == null
                ? null
                : () {
                    notifier.addDocument(
                      coachName,
                      _newDocType,
                      _newExpiryDate!,
                    );
                    setState(() => _newExpiryDate = null);
                  },
          ),
        ],
      ),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  final ComplianceDocType docType;
  final ComplianceDocument? document;
  final AppColors colors;
  final VoidCallback? onSign;

  const _MatrixRow({
    super.key,
    required this.docType,
    required this.document,
    required this.colors,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (label, variant) = switch (document) {
      null => ('Missing', AppTagChipVariant.error),
      final d when !d.signed => ('Unsigned', AppTagChipVariant.warning),
      final d when !d.isValid(now) => ('Expired', AppTagChipVariant.error),
      _ => ('Valid', AppTagChipVariant.success),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              complianceDocTypeLabels[docType]!,
              style: AppTypography.body,
            ),
          ),
          if (document != null)
            Text(
              'Expires ${document!.expiryDate.day}/${document!.expiryDate.month}/${document!.expiryDate.year}',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          const SizedBox(width: AppSpacing.sm),
          AppTagChip(label: label, variant: variant),
          if (document != null && !document!.signed)
            TextButton(onPressed: onSign, child: const Text('Sign')),
        ],
      ),
    );
  }
}
