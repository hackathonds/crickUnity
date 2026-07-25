import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_money_text.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_swipe_action_row.dart';
import 'app_tag_chip.dart';

/// Digit grouping for a display amount — every 3 digits, matching
/// [AppCurrencyField]'s input formatter for consistency. [AppMoneyText]
/// (built in E0-02, `tokens/app_money_text.dart`) takes a pre-formatted
/// `String` and doesn't group digits itself, so callers do it here.
String _formatGrouped(num amount) {
  final digits = amount.truncate().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// DS §3.2.5 Expense Card (Home summary, 96h). Money surface — mandatory
/// 1px border in every theme via `AppCard(isMoneySurface: true)`; no
/// gamification color, no celebration animation (non-negotiable #7).
class AppExpenseCard extends StatelessWidget {
  final bool isOwedToMe;
  final num amount;
  final String counterpartyName;
  final int pendingCount;
  final int? overdueDays;
  final VoidCallback? onSettleUp;
  final VoidCallback? onRemind;

  const AppExpenseCard({
    super.key,
    required this.isOwedToMe,
    required this.amount,
    required this.counterpartyName,
    required this.pendingCount,
    this.overdueDays,
    this.onSettleUp,
    this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final moneyStyle = AppTypography.moneyMin.copyWith(
      fontSize: 22,
      color: isOwedToMe ? colors.success : colors.textPrimary,
    );

    return AppCard(
      isMoneySurface: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.body.copyWith(
                      color: isOwedToMe ? colors.success : colors.textPrimary,
                    ),
                    children: [
                      TextSpan(text: isOwedToMe ? 'You are owed ' : 'You owe '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: AppMoneyText(
                          symbol: '₹',
                          amount: _formatGrouped(amount),
                          numeralStyle: moneyStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_overdueVariant(overdueDays) != null) ...[
                const SizedBox(width: AppSpacing.sm),
                AppTagChip(
                  label: '${overdueDays}d overdue',
                  variant: _overdueVariant(overdueDays)!,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$counterpartyName · $pendingCount pending',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppButton(
                variant: AppButtonVariant.tertiary,
                label: 'Settle up',
                onPressed: onSettleUp,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                variant: AppButtonVariant.tertiary,
                label: 'Remind',
                onPressed: onRemind,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

AppTagChipVariant? _overdueVariant(int? overdueDays) {
  if (overdueDays == null || overdueDays <= 3) return null;
  return overdueDays > 7 ? AppTagChipVariant.error : AppTagChipVariant.warning;
}

/// DS §3.2.6's state dots: hollow=pending, half=partial, solid=settled,
/// slash=disputed.
enum AppExpenseRowState { pending, partial, settled, disputed }

class _StateDotPainter extends CustomPainter {
  final AppExpenseRowState state;
  final Color color;

  _StateDotPainter({required this.state, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (state) {
      case AppExpenseRowState.pending:
        canvas.drawCircle(center, radius - 1, strokePaint);
      case AppExpenseRowState.partial:
        canvas.drawCircle(center, radius - 1, strokePaint);
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
        canvas.drawCircle(center, radius - 1, fillPaint);
        canvas.restore();
      case AppExpenseRowState.settled:
        canvas.drawCircle(center, radius - 1, fillPaint);
      case AppExpenseRowState.disputed:
        canvas.drawCircle(center, radius - 1, strokePaint);
        canvas.drawLine(
          Offset(size.width * 0.2, size.height * 0.8),
          Offset(size.width * 0.8, size.height * 0.2),
          strokePaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _StateDotPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.color != color;
  }
}

/// DS §3.2.6 Expense Row (ledger, 64h). A plain list row, not an
/// `AppCard` — DS's own anatomy string never mentions a surface/border/
/// elevation for it, unlike every genuine Card in §3.2.1-3.2.9,
/// consistent with a ledger row meant to sit inside a scrollable list
/// with row dividers rather than float as its own card.
class AppExpenseRow extends StatelessWidget {
  final AppIconId categoryIcon;
  final String title;
  final String contextCaption;
  final num amount;
  final AppExpenseRowState state;
  final VoidCallback? onPaySettle;
  final VoidCallback? onRemindDispute;

  const AppExpenseRow({
    super.key,
    required this.title,
    required this.contextCaption,
    required this.amount,
    required this.state,
    this.categoryIcon = AppIconId.receipt,
    this.onPaySettle,
    this.onRemindDispute,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final row = SizedBox(
      key: const ValueKey('appExpenseRowBox'),
      height: 64,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            AppIcon(
              id: categoryIcon,
              semanticLabel: title,
              color: colors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    contextCaption,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppMoneyText(
              symbol: '₹',
              amount: _formatGrouped(amount),
              numeralStyle: AppTypography.moneyMin.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CustomPaint(
              key: const ValueKey('appExpenseRowStateDot'),
              size: const Size(12, 12),
              painter: _StateDotPainter(
                state: state,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    if (onPaySettle == null && onRemindDispute == null) return row;

    return AppSwipeActionRow(
      leftAction: onPaySettle == null
          ? null
          : AppSwipeAction(
              icon: AppIconId.settleHandshake,
              label: 'Pay/Settle',
              color: colors.success,
              onTrigger: onPaySettle!,
            ),
      rightAction: onRemindDispute == null
          ? null
          : AppSwipeAction(
              icon: AppIconId.remindBell,
              label: 'Remind/Dispute',
              color: colors.warning,
              onTrigger: onRemindDispute!,
            ),
      child: row,
    );
  }
}
