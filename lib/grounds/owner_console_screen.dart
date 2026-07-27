import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'booking_models.dart';
import 'bookings_provider.dart';
import 'grounds_provider.dart';
import 'owner_console_provider.dart';
import 'reviews_provider.dart';

/// PRD §10.6 (Owner Dashboard): "Occupancy % by weekpart, revenue
/// trends, repeat-team rate, review sentiment, price-suggestion nudges
/// ('Sat 6 AM books out in 2h — consider +10%'), payout ledger.
/// Maintenance: block slots with reason (public sees 'Maintenance');
/// recurring blocks. Staff: caretaker sub-accounts (check-in/no-show
/// marking only; no pricing/finance)." PRD §2.11 restricts owners from
/// seeing "teams' internal finances" -- this console only ever
/// surfaces this ground's own booking/review data, never a team's.
///
/// Occupancy/revenue/sentiment/nudges are computed live here from the
/// real bookingsProvider/reviewsProvider state (same "wire the real
/// module" convention as every other cross-story integration this
/// session), not static mock numbers. "Weekpart" bucketing (weekday vs.
/// weekend) and the nudge threshold are flagged judgment calls -- PRD
/// names the concept, not the exact bucketing or trigger. Payout
/// ledger has no real payment/bank-payout integration (flagged, same
/// convention as other missing-infra gaps); it lists this ground's
/// confirmed/completed booking charges as mock ledger lines. Repeat-
/// team rate has no per-renter identity to compute from (no multi-
/// account system exists) -- shown as a flagged "not available" note
/// rather than a fabricated number.
class OwnerConsoleScreen extends ConsumerStatefulWidget {
  final String groundId;

  const OwnerConsoleScreen({super.key, required this.groundId});

  @override
  ConsumerState<OwnerConsoleScreen> createState() => _OwnerConsoleScreenState();
}

class _OwnerConsoleScreenState extends ConsumerState<OwnerConsoleScreen> {
  int _blockDayOffset = 0;
  int _blockHour = 6;
  final _reasonController = TextEditingController(text: 'Pitch maintenance');
  bool _recurring = false;
  final _staffNameController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _staffNameController.dispose();
    super.dispose();
  }

  bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ground = ref.watch(groundsProvider).groundById(widget.groundId);
    if (ground == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Owner console')),
        body: const Center(child: Text('Ground not found.')),
      );
    }

    final bookings = ref
        .watch(bookingsProvider)
        .bookings
        .where((b) => b.groundId == ground.id)
        .toList();
    final reviews = ref.watch(reviewsProvider).forGround(ground.id);
    final ownerConsole = ref.watch(ownerConsoleProvider);
    final notifier = ref.read(ownerConsoleProvider.notifier);

    // 7-day observation window (5 weekdays + 2 weekend days) against the
    // 6-slots/day grid established by booking_flow_screen.dart.
    const slotsPerDay = 6;
    final weekdayCapacity = slotsPerDay * 5;
    final weekendCapacity = slotsPerDay * 2;
    final activeOrCompleted = bookings.where(
      (b) => b.isActive || b.status == BookingStatus.completed,
    );
    final weekdayBooked = activeOrCompleted
        .where((b) => !_isWeekend(b.slotStart))
        .length;
    final weekendBooked = activeOrCompleted
        .where((b) => _isWeekend(b.slotStart))
        .length;
    final weekdayOccupancy = (weekdayBooked / weekdayCapacity * 100).clamp(
      0,
      100,
    );
    final weekendOccupancy = (weekendBooked / weekendCapacity * 100).clamp(
      0,
      100,
    );

    final now = DateTime.now();
    final revenueThisMonth = activeOrCompleted
        .where(
          (b) => b.slotStart.year == now.year && b.slotStart.month == now.month,
        )
        .fold<int>(0, (sum, b) => sum + b.priceQuote);

    final avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.overallStars).reduce((a, b) => a + b) /
              reviews.length;

    // PRD names no exact nudge trigger -- 80% occupancy is a flagged
    // judgment call.
    const nudgeThreshold = 80;
    final nudges = <String>[
      if (weekendOccupancy >= nudgeThreshold)
        'Weekend slots are ${weekendOccupancy.round()}% booked -- consider a +10% price nudge.',
      if (weekdayOccupancy >= nudgeThreshold)
        'Weekday slots are ${weekdayOccupancy.round()}% booked -- consider a +10% price nudge.',
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Owner console · ${ground.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Occupancy by weekpart',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          _StatRow(
            label: 'Weekday',
            value: '${weekdayOccupancy.round()}%',
            colors: colors,
          ),
          _StatRow(
            label: 'Weekend',
            value: '${weekendOccupancy.round()}%',
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Revenue',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          _StatRow(
            label: 'This month',
            value: '₹$revenueThisMonth',
            colors: colors,
            tabular: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Repeat-team rate',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Not available -- no per-renter identity exists yet to compute repeat visits.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Review sentiment',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reviews.isEmpty
                ? 'No reviews yet.'
                : '${avgRating.toStringAsFixed(1)}★ average across ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (nudges.isNotEmpty) ...[
            Text(
              'Price-suggestion nudges',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final nudge in nudges)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.coin.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  nudge,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Payout ledger (mock -- no bank integration)',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (activeOrCompleted.isEmpty)
            Text(
              'No payouts yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final b in activeOrCompleted)
              _StatRow(
                label:
                    '${b.slotStart.day}/${b.slotStart.month} · ${b.slotStart.hour}:00',
                value: '₹${b.priceQuote}',
                colors: colors,
                tabular: true,
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Maintenance blocks',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final block in ownerConsole.maintenanceBlocks.where(
            (b) => b.groundId == ground.id,
          ))
            Container(
              key: ValueKey('maintenanceBlockRow_${block.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${block.slotStart.day}/${block.slotStart.month} ${block.slotStart.hour}:00 -- '
                      '${block.reason}${block.recurringWeekly ? ' (weekly)' : ''}',
                      style: AppTypography.body,
                    ),
                  ),
                  IconButton(
                    key: ValueKey('unblockButton_${block.id}'),
                    icon: const Icon(Icons.close),
                    onPressed: () => notifier.unblockSlot(block.id),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  key: const ValueKey('blockDayOffsetDropdown'),
                  value: _blockDayOffset,
                  items: [
                    for (var i = 0; i < 7; i++)
                      DropdownMenuItem(value: i, child: Text('+$i d')),
                  ],
                  onChanged: (v) => setState(() => _blockDayOffset = v ?? 0),
                ),
              ),
              Expanded(
                child: DropdownButton<int>(
                  key: const ValueKey('blockHourDropdown'),
                  value: _blockHour,
                  items: [
                    for (final h in [6, 8, 10, 14, 16, 18])
                      DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _blockHour = v ?? 6),
                ),
              ),
            ],
          ),
          TextField(
            key: const ValueKey('blockReasonField'),
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          CheckboxListTile(
            key: const ValueKey('blockRecurringCheckbox'),
            contentPadding: EdgeInsets.zero,
            value: _recurring,
            title: const Text('Repeat weekly'),
            onChanged: (v) => setState(() => _recurring = v ?? false),
          ),
          AppButton(
            key: const ValueKey('blockSlotButton'),
            variant: AppButtonVariant.secondary,
            label: 'Block slot',
            fullWidth: true,
            onPressed: () {
              final day = DateTime.now().add(Duration(days: _blockDayOffset));
              notifier.blockSlot(
                groundId: ground.id,
                slotStart: DateTime(day.year, day.month, day.day, _blockHour),
                reason: _reasonController.text,
                recurringWeekly: _recurring,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Staff (caretaker sub-accounts)',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final s in ownerConsole.staff)
            ListTile(
              key: ValueKey('staffRow_${s.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(s.name),
              subtitle: const Text(
                'Check-in / no-show only -- no pricing or finance access',
              ),
              trailing: IconButton(
                key: ValueKey('removeStaffButton_${s.id}'),
                icon: const Icon(Icons.close),
                onPressed: () => notifier.removeStaff(s.id),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('staffNameField'),
                  controller: _staffNameController,
                  decoration: const InputDecoration(hintText: 'Caretaker name'),
                ),
              ),
              IconButton(
                key: const ValueKey('addStaffButton'),
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () {
                  if (_staffNameController.text.trim().isEmpty) return;
                  notifier.addStaff(_staffNameController.text.trim());
                  _staffNameController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final bool tabular;

  const _StatRow({
    required this.label,
    required this.value,
    required this.colors,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style:
                (tabular
                        ? AppTypography.stat.copyWith(
                            fontSize: 15,
                            height: 22 / 15,
                          )
                        : AppTypography.body)
                    .copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
