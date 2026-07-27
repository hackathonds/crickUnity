import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'officials_console_models.dart';
import 'officials_console_provider.dart';

/// DS §11.4 (Officials suite): "Officials Console: next-assignment hero
/// card -> calendar strip -> tabs Assignments/Earnings/Ratings ...
/// Credential tier card: Arc progress to next tier ('34/50 matches to
/// Silver') + certification requirement chip linking 11.11." The
/// certification chip links out to the Knowledge Hub (DS §11.11,
/// E14-05) -- shows a forward-reference note until that story ships.
class OfficialsConsoleScreen extends ConsumerStatefulWidget {
  const OfficialsConsoleScreen({super.key});

  @override
  ConsumerState<OfficialsConsoleScreen> createState() =>
      _OfficialsConsoleScreenState();
}

class _OfficialsConsoleScreenState extends ConsumerState<OfficialsConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(officialsConsoleProvider);
    final next = state.upcomingAssignments.isEmpty
        ? null
        : state.upcomingAssignments.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Officials console'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignments'),
            Tab(text: 'Earnings'),
            Tab(text: 'Ratings'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (next != null)
            Container(
              key: const ValueKey('nextAssignmentHero'),
              width: double.infinity,
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next assignment',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    next.matchLabel,
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${next.groundName} -- ₹${next.feeRupees}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            key: const ValueKey('assignmentCalendarStrip'),
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                for (final a in state.upcomingAssignments)
                  Container(
                    key: ValueKey('calendarStripDay_${a.id}'),
                    width: 56,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${a.date.day}',
                          style: AppTypography.stat.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          _monthShort(a.date.month),
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _CredentialTierCard(
            disputeFreeMatches: state.disputeFreeMatches,
            averageRating: state.averageRating,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AssignmentsTab(assignments: state.upcomingAssignments),
                const _EarningsTab(),
                const _RatingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthShort(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _CredentialTierCard extends StatelessWidget {
  final int disputeFreeMatches;
  final double averageRating;

  const _CredentialTierCard({
    required this.disputeFreeMatches,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final tier = currentTier(disputeFreeMatches, averageRating);
    final next = nextTier(disputeFreeMatches);
    final nextThreshold = next == null ? null : credentialTierThresholds[next];
    final progress = nextThreshold == null
        ? 1.0
        : disputeFreeMatches / nextThreshold;
    final ratingGated =
        averageRating < minAverageRatingForCredentialTier &&
        disputeFreeMatches >= credentialTierThresholds[CredentialTier.bronze]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AppArcRing(
            progress: progress.clamp(0.0, 1.0),
            size: 44,
            strokeWidth: 4,
            trackColor: colors.divider,
            fillColor: colors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier == null
                      ? 'No tier yet'
                      : '${credentialTierLabels[tier]} tier',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  next == null
                      ? 'Highest tier reached'
                      : '$disputeFreeMatches/$nextThreshold matches to '
                            '${credentialTierLabels[next]}',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (ratingGated)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Rating ${averageRating.toStringAsFixed(1)} -- needs '
                      '$minAverageRatingForCredentialTier+ to hold a tier',
                      style: AppTypography.caption.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ActionChip(
            key: const ValueKey('certificationRequirementChip'),
            label: const Text('Certification'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Knowledge Hub certification tracks -- E14-05'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  final List<Assignment> assignments;

  const _AssignmentsTab({required this.assignments});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (assignments.isEmpty) {
      return Center(
        child: Text(
          'No upcoming assignments.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final a in assignments)
          Padding(
            key: ValueKey('assignmentRow_${a.id}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    a.matchLabel,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '₹${a.feeRupees}',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EarningsTab extends ConsumerWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(officialsConsoleProvider);
    final notifier = ref.read(officialsConsoleProvider.notifier);
    final monthTotal = state.ledger.fold(0, (a, r) => a + r.feeRupees);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Total this period: ₹$monthTotal',
          style: AppTypography.title.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final row in state.ledger)
          Container(
            key: ValueKey('ledgerRow_${row.matchLabel}'),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.matchLabel,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        row.status == PaymentStatus.paid ? 'Paid' : 'Pending',
                        style: AppTypography.caption.copyWith(
                          color: row.status == PaymentStatus.paid
                              ? colors.success
                              : colors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${row.feeRupees}',
                  style: AppTypography.body.copyWith(
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (row.status == PaymentStatus.pending &&
                    row.daysPending > 7 &&
                    !row.reminderSent)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: TextButton(
                      onPressed: () =>
                          notifier.requestPaymentReminder(row.matchLabel),
                      child: const Text('Remind'),
                    ),
                  )
                else if (row.reminderSent)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Text(
                      'Reminded',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RatingsTab extends ConsumerWidget {
  const _RatingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(officialsConsoleProvider);
    final notifier = ref.read(officialsConsoleProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          state.averageRating.toStringAsFixed(1),
          style: AppTypography.scoreboard.copyWith(color: colors.textPrimary),
        ),
        Text(
          'Average rating',
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final facet in state.ratingFacets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    facet.label,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: facet.score / 5,
                      minHeight: 8,
                      backgroundColor: colors.border,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  facet.score.toStringAsFixed(1),
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Recent reviews',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        for (final review in state.reviews)
          Container(
            key: ValueKey('reviewRow_${review.reviewerName}'),
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewerName,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      review.rating.toStringAsFixed(0),
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  review.comment,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (review.rating <= 3)
                  Align(
                    alignment: Alignment.centerRight,
                    child: review.disputeAppealed
                        ? Text(
                            'Appeal submitted',
                            style: AppTypography.caption.copyWith(
                              color: colors.textTertiary,
                            ),
                          )
                        : TextButton(
                            onPressed: () =>
                                notifier.appealReview(review.reviewerName),
                            child: const Text('Dispute / appeal'),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
