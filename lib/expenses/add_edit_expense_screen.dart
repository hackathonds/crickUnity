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
import '../teams/jersey_board_provider.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'recurring_series_models.dart';
import 'recurring_series_provider.dart';

class _ItemEntry {
  String label = '';
  int amount = 0;
  String? assignedTo;
}

/// Mutable editing counterpart to [VehicleGroup] -- PRD §11.2 Travel.
class _VehicleGroupInput {
  String? driverName;
  Set<String> riders = {};
  int fuelCost = 0;
  bool driverExempt = false;
}

/// DS §11.13 Scan-to-itemize: mock detected line item -- no real
/// camera/OCR pipeline exists in this codebase (flagged, same
/// convention as every other missing-device-integration mock this
/// session). [confidenceLow] mirrors "confidence-low rows flagged for
/// manual check."
class _DetectedItem {
  String name;
  int amount;
  String? assignedTo;
  final bool confidenceLow;

  _DetectedItem({
    required this.name,
    required this.amount,
    this.confidenceLow = false,
  });
}

List<_DetectedItem> _mockDetectedItems() => [
  _DetectedItem(name: 'Ground fee', amount: 500),
  _DetectedItem(name: 'Water bottles', amount: 150),
  _DetectedItem(name: 'Extra ball', amount: 150, confidenceLow: true),
];

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

  // PRD §11.2 category behaviors (E5-02).
  bool _teamWalletPays = false; // Ground Fees / Tournament Entry
  int _ballQuantity = 2; // Ball Purchase
  bool _losingTeamPays = false; // Ball Purchase
  bool _halfWithOpponent = false; // Umpire/Scorer Fees
  bool _amortizeAcrossSeason = false; // Equipment/Jersey
  int _amortizeMonths = 12; // Equipment/Jersey
  bool _proRataForJoiners = false; // Equipment/Jersey
  final List<_VehicleGroupInput> _vehicleGroups = []; // Travel
  FineChartEntry? _selectedFineReason; // Penalty/Fine
  String? _fineeName; // Penalty/Fine
  PrizeDistributionMethod _prizeDistribution = PrizeDistributionMethod.equal;
  RecurrenceCadence _cadence = RecurrenceCadence.off; // DS §11.13
  DateTime? _seriesEndDate;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  /// PRD §11.2 Umpire/Scorer Fees: "both teams half-half is the
  /// cross-team default." [_amount] stays the full agreed fee entered
  /// by the scorer; this is what our team is actually tracking.
  int get _effectiveAmount =>
      (_category == ExpenseCategory.umpireScorerFees && _halfWithOpponent)
      ? (_amount / 2).round()
      : _amount;

  int get _travelTotal => _vehicleGroups.fold(0, (s, g) => s + g.fuelCost);

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
        return equalSplit(_effectiveAmount, people, payerName: _payerName);
      case SplitMethod.custom:
        return [
          for (final p in people)
            SplitShare(name: p, amount: _customAmounts[p] ?? 0),
        ];
      case SplitMethod.shares:
        return weightedSplit(_effectiveAmount, {
          for (final p in people) p: _shareWeights[p] ?? 1,
        }, payerName: _payerName);
      case SplitMethod.percentages:
        return weightedSplit(_effectiveAmount, {
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

  /// PRD §11.2 Prize Money: distribution recipients, expressed as
  /// [PaidByEntry] rather than [SplitShare] since income flips the
  /// usual paid/owed direction -- recipients are credited, not billed.
  List<PaidByEntry> _computePrizeRecipients() {
    switch (_prizeDistribution) {
      case PrizeDistributionMethod.equal:
        return [
          for (final s in equalSplit(_effectiveAmount, _selected.toList()))
            PaidByEntry(name: s.name, amount: s.amount),
        ];
      case PrizeDistributionMethod.shares:
        return [
          for (final s in weightedSplit(_effectiveAmount, {
            for (final p in _selected) p: _shareWeights[p] ?? 1,
          }))
            PaidByEntry(name: s.name, amount: s.amount),
        ];
      case PrizeDistributionMethod.toWallet:
        return [
          PaidByEntry(name: teamWalletPayerName, amount: _effectiveAmount),
        ];
    }
  }

  bool get _isSplitValid {
    if (_category == ExpenseCategory.prizeMoney) {
      return _prizeDistribution == PrizeDistributionMethod.toWallet ||
          _selected.isNotEmpty;
    }
    if (_selected.isEmpty || _effectiveAmount <= 0) return false;
    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.attendanceBased:
      case SplitMethod.shares:
        return true;
      case SplitMethod.custom:
        return _effectiveAmount -
                _computeSplit().fold(0, (s, e) => s + e.amount) ==
            0;
      case SplitMethod.percentages:
        final total = _selected.fold(0, (s, p) => s + (_percentages[p] ?? 0));
        return total == 100;
      case SplitMethod.itemized:
        if (_items.isEmpty || _items.any((i) => i.assignedTo == null)) {
          return false;
        }
        final itemTotal = _items.fold(0, (s, i) => s + i.amount);
        return _effectiveAmount - itemTotal == 0;
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
            _effectiveAmount - _computeSplit().fold(0, (s, e) => s + e.amount);
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
    final raw = _effectiveAmount - extraSum;
    return raw < 0 ? 0 : raw;
  }

  bool get _needsApproval => _effectiveAmount > expenseApprovalThresholdRupees;

  void _save() {
    if (_category == null || _titleController.text.trim().isEmpty) {
      setState(() => _saveError = 'Fill in a title and category first.');
      return;
    }

    if (_category == ExpenseCategory.penaltyFine) {
      if (_selectedFineReason == null || _fineeName == null) {
        setState(() => _saveError = 'Pick a fine-chart reason and the finee.');
        return;
      }
      ref
          .read(expensesProvider.notifier)
          .addExpense(
            title: _selectedFineReason!.reason,
            category: _category!,
            amount: _selectedFineReason!.amount,
            paidBy: [
              PaidByEntry(
                name: teamWalletPayerName,
                amount: _selectedFineReason!.amount,
              ),
            ],
            splitMethod: SplitMethod.custom,
            splitAmong: [
              SplitShare(
                name: _fineeName!,
                amount: _selectedFineReason!.amount,
              ),
            ],
            contextMatchId: _contextMatchId,
            hasProof: _hasProof,
            createdByName: widget.viewerName,
            createdByIsCaptain: widget.viewerIsCaptain,
          );
      Navigator.of(context).pop();
      return;
    }

    if (_category == ExpenseCategory.travel) {
      final groups = [
        for (final g in _vehicleGroups)
          if (g.driverName != null && g.fuelCost > 0)
            VehicleGroup(
              driverName: g.driverName!,
              riders: g.riders.toList(),
              fuelCost: g.fuelCost,
              driverExempt: g.driverExempt,
            ),
      ];
      if (groups.isEmpty) {
        setState(
          () => _saveError = 'Add at least one vehicle with a fuel cost.',
        );
        return;
      }
      final total = _travelTotal;
      ref
          .read(expensesProvider.notifier)
          .addExpense(
            title: _titleController.text.trim(),
            category: _category!,
            amount: total,
            paidBy: [PaidByEntry(name: widget.viewerName, amount: total)],
            splitMethod: SplitMethod.custom,
            splitAmong: travelSplit(groups),
            contextMatchId: _contextMatchId,
            hasProof: _hasProof,
            createdByName: widget.viewerName,
            createdByIsCaptain: widget.viewerIsCaptain,
          );
      Navigator.of(context).pop();
      return;
    }

    if (!_isSplitValid) {
      setState(
        () => _saveError =
            'Fix the split before saving -- see the remainder line above.',
      );
      return;
    }

    final isPrize = _category == ExpenseCategory.prizeMoney;
    final usesWallet =
        _teamWalletPays &&
        (_category == ExpenseCategory.groundFees ||
            _category == ExpenseCategory.tournamentEntry);
    final splitAmong = isPrize
        ? [SplitShare(name: 'Prize pool', amount: _effectiveAmount)]
        : _computeSplit();

    String? seriesId;
    if (_cadence != RecurrenceCadence.off) {
      seriesId = ref
          .read(recurringSeriesProvider.notifier)
          .createSeries(
            title: _titleController.text.trim(),
            category: _category!,
            amount: _effectiveAmount,
            splitMethod: _splitMethod,
            splitAmong: splitAmong,
            cadence: _cadence,
            startDate: DateTime.now(),
            endDate: _seriesEndDate,
            createdByName: widget.viewerName,
            createdByIsCaptain: widget.viewerIsCaptain,
          );
    }

    ref
        .read(expensesProvider.notifier)
        .addExpense(
          title: _titleController.text.trim(),
          category: _category!,
          amount: _effectiveAmount,
          paidBy: isPrize
              ? _computePrizeRecipients()
              : usesWallet
              ? [
                  PaidByEntry(
                    name: teamWalletPayerName,
                    amount: _effectiveAmount,
                  ),
                ]
              : [
                  PaidByEntry(name: _payerName, amount: _primaryPayerAmount),
                  for (final entry in _extraPayerAmounts.entries)
                    PaidByEntry(name: entry.key, amount: entry.value),
                ],
          splitMethod: _splitMethod,
          splitAmong: splitAmong,
          contextMatchId: _contextMatchId,
          hasProof: _hasProof,
          notes: null,
          createdByName: widget.viewerName,
          createdByIsCaptain: widget.viewerIsCaptain,
          isIncome: isPrize,
          recurrenceSeriesId: seriesId,
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
                  onTap: () => setState(() {
                    _category = category;
                    // PRD §11.2 Food: "attendees only auto-list from
                    // check-ins" -- no real match check-in feed exists,
                    // so Attendance-based (the manual participant
                    // toggle already built for E5-01) stands in as the
                    // sensible default for this category specifically.
                    if (category == ExpenseCategory.food) {
                      _splitMethod = SplitMethod.attendanceBased;
                    }
                  }),
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
            ..._buildCoreSection(colors, participants),
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
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('scanReceiptButton'),
              variant: AppButtonVariant.tertiary,
              label: 'Scan receipt (detect items)',
              onPressed: () => _showScanReceiptSheet(context),
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Repeats',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSegmentedControl<RecurrenceCadence>(
              key: const ValueKey('cadenceControl'),
              options: RecurrenceCadence.values,
              value: _cadence,
              onChanged: (v) => setState(() => _cadence = v),
              labelBuilder: (v) => recurrenceCadenceLabels[v]!,
            ),
            if (_cadence != RecurrenceCadence.off) ...[
              () {
                final previewSeries = RecurringSeries(
                  id: '',
                  title: '',
                  category: _category!,
                  amount: _effectiveAmount,
                  splitMethod: _splitMethod,
                  splitAmong: const [],
                  cadence: _cadence,
                  startDate: DateTime.now(),
                  endDate: _seriesEndDate,
                  createdByName: widget.viewerName,
                  createdByIsCaptain: widget.viewerIsCaptain,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      key: const ValueKey('seriesSummaryLine'),
                      previewSeries.summaryLine,
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const ValueKey('seriesEndDateButton'),
                      variant: AppButtonVariant.tertiary,
                      label: _seriesEndDate == null
                          ? 'Set end date (optional)'
                          : 'Ends ${_seriesEndDate!.day}/'
                                '${_seriesEndDate!.month}/'
                                '${_seriesEndDate!.year}',
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _seriesEndDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Upcoming instances',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    for (final date in previewSeries.upcomingInstances())
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                );
              }(),
            ],
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

  Widget _sectionLabel(AppColors colors, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text,
      style: AppTypography.label.copyWith(color: colors.textTertiary),
    ),
  );

  /// PRD §11.2 -- dispatches to a category-specific layout for the
  /// three categories whose structure genuinely differs from the
  /// generic paid-by/split-method flow (Fine: single finee, not a
  /// split; Travel: per-vehicle sub-groups; both bypass Title/Amount
  /// too, since their totals are derived). Every other category reuses
  /// the generic flow with a small category note plus, for Prize Money,
  /// a distribution-method swap in place of the split editor.
  List<Widget> _buildCoreSection(AppColors colors, List<String> participants) {
    if (_category == ExpenseCategory.penaltyFine) {
      return _buildFineSection(colors, participants);
    }
    if (_category == ExpenseCategory.travel) {
      return _buildTravelSection(colors, participants);
    }
    final isPrize = _category == ExpenseCategory.prizeMoney;
    final usesWallet =
        _category == ExpenseCategory.groundFees ||
        _category == ExpenseCategory.tournamentEntry;

    return [
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
      const SizedBox(height: AppSpacing.sm),
      ..._buildCategoryNote(colors),
      if (!isPrize) ...[
        const SizedBox(height: AppSpacing.lg),
        _sectionLabel(colors, 'Paid by'),
        if (usesWallet)
          Row(
            children: [
              Switch(
                key: const ValueKey('teamWalletPaysSwitch'),
                value: _teamWalletPays,
                onChanged: (v) => setState(() => _teamWalletPays = v),
              ),
              Expanded(
                child: Text(
                  'Team wallet pays',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
        if (!(usesWallet && _teamWalletPays)) ...[
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
        ],
      ],
      const SizedBox(height: AppSpacing.lg),
      _sectionLabel(colors, 'Split'),
      if (isPrize)
        ..._buildPrizeDistributionSection(colors, participants)
      else ...[
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
      ],
    ];
  }

  /// One-line category behaviors that stay inside the generic flow --
  /// PRD §11.2's ground-fee/ball-purchase/umpire-fee/equipment bullets.
  List<Widget> _buildCategoryNote(AppColors colors) {
    switch (_category!) {
      case ExpenseCategory.groundFees:
        return [
          Text(
            'Auto-draft from a Ground booking isn\'t wired in yet -- enter manually.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        ];
      case ExpenseCategory.ballPurchase:
        return [
          Row(
            children: [
              Text(
                'Quantity',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              IconButton(
                key: const ValueKey('ballQuantityDecrement'),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _ballQuantity > 1
                    ? () => setState(() => _ballQuantity--)
                    : null,
              ),
              Text(
                '$_ballQuantity',
                style: AppTypography.stat.copyWith(color: colors.textPrimary),
              ),
              IconButton(
                key: const ValueKey('ballQuantityIncrement'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _ballQuantity++),
              ),
            ],
          ),
          ActionChip(
            key: const ValueKey('ballPresetSuggestionChip'),
            label: const Text('You buy ~2 balls/match -- add to preset?'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No preset-learning backend in this codebase yet',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Switch(
                key: const ValueKey('losingTeamPaysSwitch'),
                value: _losingTeamPays,
                onChanged: (v) => setState(() => _losingTeamPays = v),
              ),
              Expanded(
                child: Text(
                  'Losing team pays (pre-agreed by both captains)',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
        ];
      case ExpenseCategory.umpireScorerFees:
        return [
          Row(
            children: [
              Switch(
                key: const ValueKey('halfWithOpponentSwitch'),
                value: _halfWithOpponent,
                onChanged: (v) => setState(() => _halfWithOpponent = v),
              ),
              Expanded(
                child: Text(
                  'Split half-half with opponent team',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          if (_halfWithOpponent)
            Text(
              'Our share: ₹$_effectiveAmount (visible to both captains)',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
        ];
      case ExpenseCategory.equipmentJersey:
        return [
          Row(
            children: [
              Switch(
                key: const ValueKey('amortizeAcrossSeasonSwitch'),
                value: _amortizeAcrossSeason,
                onChanged: (v) => setState(() => _amortizeAcrossSeason = v),
              ),
              Expanded(
                child: Text(
                  'Amortize across the season',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          if (_amortizeAcrossSeason) ...[
            Row(
              children: [
                Text(
                  'Months',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                IconButton(
                  key: const ValueKey('amortizeMonthsDecrement'),
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _amortizeMonths > 1
                      ? () => setState(() => _amortizeMonths--)
                      : null,
                ),
                Text(
                  '$_amortizeMonths',
                  style: AppTypography.stat.copyWith(color: colors.textPrimary),
                ),
                IconButton(
                  key: const ValueKey('amortizeMonthsIncrement'),
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _amortizeMonths++),
                ),
              ],
            ),
            Row(
              children: [
                Switch(
                  key: const ValueKey('proRataForJoinersSwitch'),
                  value: _proRataForJoiners,
                  onChanged: (v) => setState(() => _proRataForJoiners = v),
                ),
                Expanded(
                  child: Text(
                    'Joiners mid-season pay pro-rata',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: const ValueKey('linkJerseyBoardButton'),
            variant: AppButtonVariant.tertiary,
            label: 'Link jersey board sizes',
            onPressed: _linkJerseyBoard,
          ),
        ];
      case ExpenseCategory.tournamentEntry:
        return [
          Text(
            'Refund events auto-reversing proportionally isn\'t wired in '
            'yet (no Tournament module exists).',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        ];
      case ExpenseCategory.travel:
      case ExpenseCategory.food:
      case ExpenseCategory.penaltyFine:
      case ExpenseCategory.prizeMoney:
        return const [];
    }
  }

  /// PRD §6.12/E5-02 Equipment/Jersey: "jersey links to size-sheet";
  /// per-member exact price incl. personalization. Genuinely reads the
  /// existing Jersey Board module (E3-09) -- its own price-per-member
  /// baseline seeds Custom amounts here, which the captain can then
  /// tweak per member for personalization deltas.
  void _linkJerseyBoard() {
    final jerseyState = ref.read(jerseyBoardProvider);
    final names = {for (final s in jerseyState.submissions) s.memberName};
    if (names.isEmpty) return;
    final perMember = jerseyState.pricePerMember() ?? 0;
    setState(() {
      _selected = names;
      _splitMethod = SplitMethod.custom;
      for (final name in names) {
        _customAmounts[name] = perMember;
      }
      _amountController.text = '${jerseyState.totalPriceRupees}';
    });
  }

  List<Widget> _buildFineSection(AppColors colors, List<String> participants) {
    return [
      _sectionLabel(colors, 'Fine chart'),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final entry in mockFineChart())
            ChoiceChip(
              key: ValueKey('fineReasonChip_${entry.reason}'),
              label: Text('${entry.reason} -- ₹${entry.amount}'),
              selected: _selectedFineReason == entry,
              onSelected: (_) => setState(() => _selectedFineReason = entry),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _sectionLabel(colors, 'Finee'),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final name in participants)
            ChoiceChip(
              key: ValueKey('fineeChip_$name'),
              label: Text(name),
              selected: _fineeName == name,
              onSelected: (_) => setState(() => _fineeName = name),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Collected fines default into Team Wallet, earmarked "team fund."',
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
    ];
  }

  List<Widget> _buildTravelSection(
    AppColors colors,
    List<String> participants,
  ) {
    return [
      AppTextField(
        key: const ValueKey('expenseTitleField'),
        label: 'Trip title',
        controller: _titleController,
      ),
      const SizedBox(height: AppSpacing.lg),
      _sectionLabel(colors, 'Vehicles'),
      for (var i = 0; i < _vehicleGroups.length; i++)
        Container(
          key: ValueKey('vehicleGroupCard_$i'),
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
                'Driver',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final name in participants)
                    ChoiceChip(
                      key: ValueKey('vehicleDriverChip_${i}_$name'),
                      label: Text(name),
                      selected: _vehicleGroups[i].driverName == name,
                      onSelected: (_) =>
                          setState(() => _vehicleGroups[i].driverName = name),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Riders',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final name in participants)
                    FilterChip(
                      key: ValueKey('vehicleRiderChip_${i}_$name'),
                      label: Text(name),
                      selected: _vehicleGroups[i].riders.contains(name),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _vehicleGroups[i].riders.add(name);
                        } else {
                          _vehicleGroups[i].riders.remove(name);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppCurrencyField(
                key: ValueKey('vehicleFuelCostField_$i'),
                label: 'Fuel cost',
                onChanged: (v) => setState(
                  () => _vehicleGroups[i].fuelCost =
                      int.tryParse(v.replaceAll(',', '')) ?? 0,
                ),
              ),
              Row(
                children: [
                  Switch(
                    key: ValueKey('vehicleDriverExemptSwitch_$i'),
                    value: _vehicleGroups[i].driverExempt,
                    onChanged: (v) =>
                        setState(() => _vehicleGroups[i].driverExempt = v),
                  ),
                  Expanded(
                    child: Text(
                      'Driver exempt from the fuel split',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('removeVehicleButton_$i'),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _vehicleGroups.removeAt(i)),
                  ),
                ],
              ),
            ],
          ),
        ),
      AppButton(
        key: const ValueKey('addVehicleButton'),
        variant: AppButtonVariant.tertiary,
        label: 'Add vehicle',
        onPressed: () =>
            setState(() => _vehicleGroups.add(_VehicleGroupInput())),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        key: const ValueKey('travelTotalText'),
        'Total: ₹$_travelTotal',
        style: AppTypography.stat.copyWith(color: colors.textPrimary),
      ),
    ];
  }

  List<Widget> _buildPrizeDistributionSection(
    AppColors colors,
    List<String> participants,
  ) {
    return [
      AppSegmentedControl<PrizeDistributionMethod>(
        key: const ValueKey('prizeDistributionControl'),
        options: PrizeDistributionMethod.values,
        value: _prizeDistribution,
        onChanged: (v) => setState(() => _prizeDistribution = v),
        labelBuilder: (v) => prizeDistributionLabels[v]!,
      ),
      const SizedBox(height: AppSpacing.sm),
      if (_prizeDistribution != PrizeDistributionMethod.toWallet) ...[
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final name in participants)
              FilterChip(
                key: ValueKey('prizeParticipantChip_$name'),
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
        if (_prizeDistribution == PrizeDistributionMethod.shares)
          for (final name in _selected)
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
                    key: ValueKey('prizeShareDecrement_$name'),
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
                    key: ValueKey('prizeShareIncrement_$name'),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(
                      () =>
                          _shareWeights[name] = (_shareWeights[name] ?? 1) + 1,
                    ),
                  ),
                ],
              ),
            ),
      ],
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Every member sees this distribution math:',
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
      for (final recipient in _computePrizeRecipients())
        Padding(
          key: ValueKey('prizeRecipientRow_${recipient.name}'),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  recipient.name,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Text(
                '₹${recipient.amount}',
                style: AppTypography.stat.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
    ];
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

  /// DS §11.13: "proof camera -> detected line-items sheet as editable
  /// rows (name+amount) with per-row assignee avatars multi-select;
  /// confidence-low rows flagged for manual check; [Looks right]
  /// confirms -- every line user-confirmed before save." Confirmed rows
  /// populate this screen's existing Itemized-split mechanism (E5-01)
  /// rather than a parallel one. Only a single assignee per row is
  /// supported here (reusing the existing itemized-split assignee
  /// picker) -- DS's literal "multi-select" (splitting one item across
  /// several people) isn't built, flagged as a simplification.
  void _showScanReceiptSheet(BuildContext context) {
    final items = _mockDetectedItems();
    showAppBottomSheet<void>(
      context: context,
      title: 'Detected items',
      contentBuilder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = Theme.of(context).extension<AppColors>()!;
          final allConfirmed = items.every((i) => i.assignedTo != null);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    key: ValueKey('detectedItemRow_$i'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                key: ValueKey('detectedItemName_$i'),
                                label: 'Item',
                                controller: TextEditingController(
                                  text: items[i].name,
                                ),
                                onChanged: (v) => items[i].name = v,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            SizedBox(
                              width: 90,
                              child: AppCurrencyField(
                                key: ValueKey('detectedItemAmount_$i'),
                                label: '',
                                controller: TextEditingController(
                                  text: '${items[i].amount}',
                                ),
                                onChanged: (v) => items[i].amount =
                                    int.tryParse(v.replaceAll(',', '')) ?? 0,
                              ),
                            ),
                          ],
                        ),
                        if (items[i].confidenceLow)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: AppTagChip(
                              label: 'Low confidence -- check',
                              variant: AppTagChipVariant.warning,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            for (final name in _participants)
                              ChoiceChip(
                                key: ValueKey('detectedItemAssign_${i}_$name'),
                                label: Text(name),
                                selected: items[i].assignedTo == name,
                                onSelected: (_) => setSheetState(
                                  () => items[i].assignedTo = name,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                AppButton(
                  key: const ValueKey('looksRightButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Looks right',
                  fullWidth: true,
                  onPressed: allConfirmed
                      ? () {
                          setState(() {
                            _splitMethod = SplitMethod.itemized;
                            _items
                              ..clear()
                              ..addAll([
                                for (final d in items)
                                  _ItemEntry()
                                    ..label = d.name
                                    ..amount = d.amount
                                    ..assignedTo = d.assignedTo,
                              ]);
                            _selected = {for (final d in items) d.assignedTo!};
                          });
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
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
