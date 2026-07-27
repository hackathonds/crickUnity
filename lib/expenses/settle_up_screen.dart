import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_currency_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'settlement_models.dart';
import 'settlements_provider.dart';

/// DS §7-51 (Settle Up): "counterpart picker (pre-filled from entry) ->
/// simplify suggestion card ('3 payments instead of 7' [Use]) -> amount
/// (full/partial chips) -> method note -> confirm -> success handshake
/// (§5.10) -> both ledgers update." PRD §11.6: the settle *claim* is
/// what [Confirm] here records (matching DS's screen-level "confirm ->
/// handshake -> ledgers update"); the counterpart's actual receipt-
/// confirmation (single tap, 72h auto-confirm, decline -> mini-dispute)
/// is the fuller lifecycle PRD's prose describes, surfaced separately
/// in Expenses Home's "Pending settlements" section.
class SettleUpScreen extends ConsumerStatefulWidget {
  final String viewerName;
  final String? prefilledCounterpartName;

  const SettleUpScreen({
    super.key,
    required this.viewerName,
    this.prefilledCounterpartName,
  });

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

enum _AmountMode { full, partial, custom }

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  String? _counterpart;
  int? _suggestedAmount;
  _AmountMode _amountMode = _AmountMode.full;
  final _customController = TextEditingController();
  SettlementMethod _method = SettlementMethod.upi;
  bool _viewerIsPayer = true;
  bool _showHandshake = false;

  @override
  void initState() {
    super.initState();
    _counterpart = widget.prefilledCounterpartName;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref
        .watch(expensesProvider)
        .expenses
        .where((e) => !e.isDeleted)
        .toList();
    final settlements = ref.watch(settlementsProvider).settlements;
    final notifier = ref.read(settlementsProvider.notifier);

    final counterparts = [
      for (final name in mockExpenseParticipants())
        if (name != widget.viewerName) name,
    ];
    final netBalances = netBalancesByPerson(expenses, settlements, {
      widget.viewerName,
      ...counterparts,
    });
    final suggestions = [
      for (final s in simplifyDebts(netBalances))
        if (s.fromName == widget.viewerName || s.toName == widget.viewerName) s,
    ];

    final viewerNet = netBalances[widget.viewerName] ?? 0;
    final fullAmount = _suggestedAmount ?? viewerNet.abs();
    final amount = switch (_amountMode) {
      _AmountMode.full => fullAmount,
      _AmountMode.partial => (fullAmount / 2).round(),
      _AmountMode.custom =>
        int.tryParse(_customController.text.replaceAll(',', '')) ?? 0,
    };

    if (_showHandshake) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settle up')),
        body: Center(
          child: TweenAnimationBuilder<double>(
            key: const ValueKey('handshakeAnimation'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 48,
                  color: colors.verified,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Settlement recorded',
                  style: AppTypography.h2.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Waiting for confirmation from the other side.',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  key: const ValueKey('handshakeDoneButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Counterpart',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final name in counterparts)
                ChoiceChip(
                  key: ValueKey('counterpartChip_$name'),
                  label: Text(name),
                  selected: _counterpart == name,
                  onSelected: (_) => setState(() {
                    _counterpart = name;
                    _suggestedAmount = null;
                  }),
                ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              key: const ValueKey('simplifySuggestionCard'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${suggestions.length} payment'
                    '${suggestions.length == 1 ? '' : 's'} instead of '
                    '${netBalances.values.where((v) => v != 0).length}',
                    style: AppTypography.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final s in suggestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs / 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${s.fromName} -> ${s.toName}: ₹${s.amount}',
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          AppButton(
                            key: ValueKey(
                              'useSuggestionButton_${s.fromName}_${s.toName}',
                            ),
                            variant: AppButtonVariant.tertiary,
                            label: 'Use',
                            onPressed: () => setState(() {
                              _counterpart = s.fromName == widget.viewerName
                                  ? s.toName
                                  : s.fromName;
                              _viewerIsPayer = s.fromName == widget.viewerName;
                              _suggestedAmount = s.amount;
                              _amountMode = _AmountMode.full;
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_counterpart != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _viewerIsPayer
                        ? '${widget.viewerName} pays $_counterpart'
                        : '$_counterpart pays ${widget.viewerName}',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  key: const ValueKey('flipDirectionButton'),
                  variant: AppButtonVariant.tertiary,
                  label: 'Flip',
                  onPressed: () =>
                      setState(() => _viewerIsPayer = !_viewerIsPayer),
                ),
              ],
            ),
            if (_suggestedAmount == null)
              Text(
                'No exact per-pair ledger exists yet -- amount defaults to '
                '${widget.viewerName}\'s overall outstanding balance.',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Amount',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  key: const ValueKey('amountModeFull'),
                  label: Text('Full (₹$fullAmount)'),
                  selected: _amountMode == _AmountMode.full,
                  onSelected: (_) =>
                      setState(() => _amountMode = _AmountMode.full),
                ),
                ChoiceChip(
                  key: const ValueKey('amountModePartial'),
                  label: Text('Partial (₹${(fullAmount / 2).round()})'),
                  selected: _amountMode == _AmountMode.partial,
                  onSelected: (_) =>
                      setState(() => _amountMode = _AmountMode.partial),
                ),
                ChoiceChip(
                  key: const ValueKey('amountModeCustom'),
                  label: const Text('Custom'),
                  selected: _amountMode == _AmountMode.custom,
                  onSelected: (_) =>
                      setState(() => _amountMode = _AmountMode.custom),
                ),
              ],
            ),
            if (_amountMode == _AmountMode.custom) ...[
              const SizedBox(height: AppSpacing.sm),
              AppCurrencyField(
                key: const ValueKey('customAmountField'),
                label: 'Amount',
                controller: _customController,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Method note',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final method in SettlementMethod.values)
                  ChoiceChip(
                    key: ValueKey('methodChip_${method.name}'),
                    label: Text(settlementMethodLabels[method]!),
                    selected: _method == method,
                    onSelected: (_) => setState(() => _method = method),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              key: const ValueKey('confirmSettlementButton'),
              variant: AppButtonVariant.primary,
              label: 'Confirm',
              fullWidth: true,
              onPressed: amount <= 0
                  ? null
                  : () {
                      notifier.proposeSettlement(
                        fromName: _viewerIsPayer
                            ? widget.viewerName
                            : _counterpart!,
                        toName: _viewerIsPayer
                            ? _counterpart!
                            : widget.viewerName,
                        amount: amount,
                        method: _method,
                      );
                      setState(() => _showHandshake = true);
                    },
            ),
          ],
        ],
      ),
    );
  }
}
