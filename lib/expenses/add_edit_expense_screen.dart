import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_currency_field.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/match_models.dart';
import '../matches/matches_provider.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';

class _ItemEntry {
  String label = '';
  int amount = 0;
  String? assignedTo;
}

/// DS §7-49 (Add/Edit Expense): "category grid (glyphs) first (drives
/// smart form) -> amount pad-first field -> paid-by selector -> split
/// editor: method segmented (Equal/Custom/Shares/%/Items/Attendance)
/// with per-person rows and live remainder line -> proof attach
/// (camera-first, +5 coin chip) -> context link -> [Save]/(Approval
/// note if >threshold). Validation: totals must equal -- mismatch
/// shows exact delta in error." PRD §11.7: team threshold (default
/// ₹1,000); self-created captain expenses above threshold route to
/// VC/Owner instead of Captain (no self-approval).
class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String viewerName;
  final bool viewerIsCaptain;

  const AddEditExpenseScreen({
    super.key,
    required this.viewerName,
    required this.viewerIsCaptain,
  });

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  ExpenseCategory? _category;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  SplitMethod _splitMethod = SplitMethod.equal;
  Set<String> _selected = mockExpenseParticipants().toSet();
  final Map<String, int> _customAmounts = {};
  final Map<String, int> _shareWeights = {};
  final Map<String, int> _percentages = {};
  final List<_ItemEntry> _items = [];
  late String _payerName = widget.viewerName;
  final Map<String, int> _extraPayerAmounts = {};
  bool _hasProof = false;
  String? _contextMatchId;
  String? _saveError;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  List<String> get _participants {
    if (_contextMatchId != null) {
      final matches = ref
          .read(matchesProvider)
          .matches
          .where((m) => m.id == _contextMatchId);
      if (matches.isNotEmpty && matches.first.squadNames.isNotEmpty) {
        return matches.first.squadNames;
      }
    }
    return mockExpenseParticipants();
  }

  List<SplitShare> _computeSplit() {
    final people = _selected.toList();
    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.attendanceBased:
        return equalSplit(_amount, people, payerName: _payerName);
      case SplitMethod.custom:
        return [
          for (final p in people)
            SplitShare(name: p, amount: _customAmounts[p] ?? 0),
        ];
      case SplitMethod.shares:
        return weightedSplit(_amount, {
          for (final p in people) p: _shareWeights[p] ?? 1,
        }, payerName: _payerName);
      case SplitMethod.percentages:
        return weightedSplit(_amount, {
          for (final p in people) p: _percentages[p] ?? 0,
        }, payerName: _payerName);
      case SplitMethod.itemized:
        final totals = <String, int>{};
        for (final item in _items) {
          if (item.assignedTo == null) continue;
          totals[item.assignedTo!] =
              (totals[item.assignedTo!] ?? 0) + item.amount;
        }
        return [
          for (final p in people) SplitShare(name: p, amount: totals[p] ?? 0),
        ];
    }
  }

  bool get _isSplitValid {
    if (_selected.isEmpty || _amount <= 0) return false;
    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.attendanceBased:
      case SplitMethod.shares:
        return true;
      case SplitMethod.custom:
        return _amount - _computeSplit().fold(0, (s, e) => s + e.amount) == 0;
      case SplitMethod.percentages:
        final total = _selected.fold(0, (s, p) => s + (_percentages[p] ?? 0));
        return total == 100;
      case SplitMethod.itemized:
        if (_items.isEmpty || _items.any((i) => i.assignedTo == null))
          return false;
        final itemTotal = _items.fold(0, (s, i) => s + i.amount);
        return _amount - itemTotal == 0;
    }
  }

  String get _remainderText {
    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.attendanceBased:
      case SplitMethod.shares:
        return 'Splits computed automatically -- remainder goes to the payer.';
      case SplitMethod.custom:
      case SplitMethod.itemized:
        final remainder =
            _amount - _computeSplit().fold(0, (s, e) => s + e.amount);
        return remainder == 0
            ? 'Splits match the total.'
            : '₹$remainder remaining -> assign it to close the split.';
      case SplitMethod.percentages:
        final total = _selected.fold(0, (s, p) => s + (_percentages[p] ?? 0));
        return total == 100
            ? 'Percentages total 100%.'
            : '${100 - total}% remaining -> assign it to reach 100%.';
    }
  }

  int get _primaryPayerAmount {
    var extraSum = 0;
    for (final v in _extraPayerAmounts.values) {
      extraSum += v;
    }
    final raw = _amount - extraSum;
    return raw < 0 ? 0 : raw;
  }

  bool get _needsApproval => _amount > expenseApprovalThresholdRupees;

  void _save() {
    if (_category == null ||
        _titleController.text.trim().isEmpty ||
        !_isSplitValid) {
      setState(
        () => _saveError =
            'Fix the split before saving -- see the remainder line above.',
      );
      return;
    }
    ref
        .read(expensesProvider.notifier)
        .addExpense(
          title: _titleController.text.trim(),
          category: _category!,
          amount: _amount,
          paidBy: [
            PaidByEntry(name: _payerName, amount: _primaryPayerAmount),
            for (final entry in _extraPayerAmounts.entries)
              PaidByEntry(name: entry.key, amount: entry.value),
          ],
          splitMethod: _splitMethod,
          splitAmong: _computeSplit(),
          contextMatchId: _contextMatchId,
          hasProof: _hasProof,
          notes: null,
          createdByName: widget.viewerName,
          createdByIsCaptain: widget.viewerIsCaptain,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final participants = _participants;

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Category',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.count(
            key: const ValueKey('categoryGrid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.1,
            children: [
              for (final category in ExpenseCategory.values)
                GestureDetector(
                  key: ValueKey('categoryTile_${category.name}'),
                  onTap: () => setState(() => _category = category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _category == category
                          ? colors.primary.withValues(alpha: 0.12)
                          : colors.surfaceAlt,
                      border: _category == category
                          ? Border.all(color: colors.primary)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          expenseCategoryIcons[category],
                          color: colors.textPrimary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          expenseCategoryLabels[category]!,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_category != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              key: const ValueKey('expenseTitleField'),
              label: 'Title',
              controller: _titleController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCurrencyField(
              key: const ValueKey('expenseAmountField'),
              label: 'Amount',
              controller: _amountController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Paid by',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final name in participants)
                  ChoiceChip(
                    key: ValueKey('payerChip_$name'),
                    label: Text(name),
                    selected: _payerName == name,
                    onSelected: (_) => setState(() => _payerName = name),
                  ),
              ],
            ),
            if (_extraPayerAmounts.isNotEmpty)
              for (final entry in _extraPayerAmounts.entries)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${entry.key}: ₹${entry.value}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            AppButton(
              key: const ValueKey('addAnotherPayerButton'),
              variant: AppButtonVariant.tertiary,
              label: 'Add another payer',
              onPressed: () => _showAddPayerSheet(participants),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Split',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSegmentedControl<SplitMethod>(
              key: const ValueKey('splitMethodControl'),
              options: SplitMethod.values,
              value: _splitMethod,
              onChanged: (v) => setState(() => _splitMethod = v),
              labelBuilder: (v) => splitMethodLabels[v]!,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final name in participants)
                  FilterChip(
                    key: ValueKey('splitParticipantChip_$name'),
                    label: Text(name),
                    selected: _selected.contains(name),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selected.add(name);
                      } else {
                        _selected.remove(name);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._buildSplitInputs(colors),
            const SizedBox(height: AppSpacing.sm),
            Text(
              key: const ValueKey('splitRemainderLine'),
              _remainderText,
              style: AppTypography.caption.copyWith(
                color: _isSplitValid ? colors.textTertiary : colors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  _hasProof ? Icons.check_circle : Icons.camera_alt_outlined,
                  color: _hasProof ? colors.verified : colors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('attachProofButton'),
                    variant: AppButtonVariant.secondary,
                    label: _hasProof ? 'Proof attached' : 'Attach proof',
                    onPressed: _hasProof
                        ? null
                        : () => setState(() => _hasProof = true),
                  ),
                ),
                if (_hasProof) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const AppTagChip(
                    label: '+5 coins',
                    variant: AppTagChipVariant.success,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Context link (optional)',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const ValueKey('linkContextButton'),
              variant: AppButtonVariant.tertiary,
              label: _contextMatchId == null
                  ? 'Link a match'
                  : 'Linked -- change',
              onPressed: _showContextLinkSheet,
            ),
            if (_needsApproval) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                key: const ValueKey('approvalNote'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.viewerIsCaptain
                      ? 'Over ₹$expenseApprovalThresholdRupees and self-created -- '
                            'routes to $mockVcOrOwnerName for approval (no self-approval).'
                      : 'Over ₹$expenseApprovalThresholdRupees -- routes to your '
                            'captain for approval before shares go live.',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _saveError!,
                key: const ValueKey('saveErrorText'),
                style: AppTypography.caption.copyWith(color: colors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('saveExpenseButton'),
              variant: AppButtonVariant.primary,
              label: 'Save',
              fullWidth: true,
              onPressed: _save,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSplitInputs(AppColors colors) {
    final people = _selected.toList();
    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.attendanceBased:
        final shares = _computeSplit();
        return [
          for (final share in shares)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      share.name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${share.amount}',
                    style: AppTypography.stat.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ];
      case SplitMethod.custom:
        return [
          for (final name in people)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppCurrencyField(
                      key: ValueKey('customAmountField_$name'),
                      label: '',
                      onChanged: (v) => setState(
                        () => _customAmounts[name] =
                            int.tryParse(v.replaceAll(',', '')) ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ];
      case SplitMethod.shares:
        return [
          for (final name in people)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('shareDecrement_$name'),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: (_shareWeights[name] ?? 1) > 1
                        ? () => setState(
                            () => _shareWeights[name] =
                                (_shareWeights[name] ?? 1) - 1,
                          )
                        : null,
                  ),
                  Text(
                    '${_shareWeights[name] ?? 1}',
                    style: AppTypography.stat.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    key: ValueKey('shareIncrement_$name'),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(
                      () =>
                          _shareWeights[name] = (_shareWeights[name] ?? 1) + 1,
                    ),
                  ),
                ],
              ),
            ),
        ];
      case SplitMethod.percentages:
        return [
          for (final name in people)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: AppTextField(
                      key: ValueKey('percentField_$name'),
                      label: '%',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(
                        () => _percentages[name] = int.tryParse(v) ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ];
      case SplitMethod.itemized:
        return [
          for (var i = 0; i < _items.length; i++)
            Padding(
              key: ValueKey('itemRow_$i'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      key: ValueKey('itemLabelField_$i'),
                      label: 'Item',
                      onChanged: (v) => setState(() => _items[i].label = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 90,
                    child: AppCurrencyField(
                      key: ValueKey('itemAmountField_$i'),
                      label: '',
                      onChanged: (v) => setState(
                        () => _items[i].amount =
                            int.tryParse(v.replaceAll(',', '')) ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final name in people)
                    ChoiceChip(
                      key: ValueKey('itemAssignChip_${i}_$name'),
                      label: Text(name),
                      selected: _items[i].assignedTo == name,
                      onSelected: (_) =>
                          setState(() => _items[i].assignedTo = name),
                    ),
                ],
              ),
            ),
          AppButton(
            key: const ValueKey('addItemButton'),
            variant: AppButtonVariant.tertiary,
            label: 'Add item',
            onPressed: () => setState(() => _items.add(_ItemEntry())),
          ),
        ];
    }
  }

  void _showAddPayerSheet(List<String> participants) {
    final controller = TextEditingController();
    String? selectedName;
    showAppBottomSheet<void>(
      context: context,
      title: 'Add another payer',
      contentBuilder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final name in participants)
                    if (name != _payerName)
                      ChoiceChip(
                        key: ValueKey('extraPayerChip_$name'),
                        label: Text(name),
                        selected: selectedName == name,
                        onSelected: (_) =>
                            setSheetState(() => selectedName = name),
                      ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCurrencyField(
                key: const ValueKey('extraPayerAmountField'),
                label: 'Amount',
                controller: controller,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                key: const ValueKey('confirmAddPayerButton'),
                variant: AppButtonVariant.primary,
                label: 'Add',
                fullWidth: true,
                onPressed: selectedName == null
                    ? null
                    : () {
                        setState(
                          () => _extraPayerAmounts[selectedName!] =
                              int.tryParse(
                                controller.text.replaceAll(',', ''),
                              ) ??
                              0,
                        );
                        Navigator.of(context).pop();
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextLinkSheet() {
    final matches = ref
        .read(matchesProvider)
        .matches
        .where((m) => m.status == MatchStatus.accepted)
        .toList();
    showAppBottomSheet<void>(
      context: context,
      title: 'Link a match',
      contentBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No accepted matches to link yet.',
                  style: AppTypography.body,
                ),
              ),
            for (final match in matches)
              GestureDetector(
                key: ValueKey('contextMatchOption_${match.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _contextMatchId = match.id;
                    _selected = _participants.toSet();
                  });
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    '${match.composerTeamName} vs ${match.draft.opponentTeamName}',
                    style: AppTypography.body,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
