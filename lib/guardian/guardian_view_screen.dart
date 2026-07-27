import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'guardian_view_models.dart';
import 'guardian_view_provider.dart';

/// DS §11.16: "Guardian view (guardian's drawer): child cards ->
/// per-child dashboard (followers/messages surface read-only, coach
/// notes, session completion, consents pending queue with approve
/// sheets)."
class GuardianViewScreen extends ConsumerWidget {
  const GuardianViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(guardianViewProvider).children;

    return Scaffold(
      appBar: AppBar(title: const Text('Guardian view')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final child in children)
            Card(
              key: ValueKey('childCard_${child.name}'),
              child: ListTile(
                title: Text(child.name),
                subtitle: Text('Age ${child.age}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChildDashboardScreen(childName: child.name),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChildDashboardScreen extends ConsumerWidget {
  final String childName;

  const ChildDashboardScreen({super.key, required this.childName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(guardianViewProvider);
    final notifier = ref.read(guardianViewProvider.notifier);
    final child = state.children.firstWhere((c) => c.name == childName);
    final notes = state.coachNotes
        .where((n) => n.childName == childName)
        .toList();
    final completion = state.sessionCompletions
        .where((s) => s.childName == childName)
        .firstOrNull;
    final consents = state.pendingConsents
        .where((c) => c.childName == childName)
        .toList();

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(childName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sectionLabel('Followers / messages (read-only)'),
          Row(
            children: [
              Expanded(
                child: _ReadOnlyStat(
                  label: 'Followers',
                  value: '${child.followerCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ReadOnlyStat(
                  label: 'Pending message requests',
                  value: '${child.pendingMessageRequests}',
                ),
              ),
            ],
          ),
          sectionLabel('Session completion'),
          if (completion != null)
            _ReadOnlyStat(
              label: 'This month',
              value:
                  '${completion.completedThisMonth}/${completion.totalThisMonth}',
            ),
          sectionLabel('Coach notes'),
          if (notes.isEmpty)
            Text(
              'No coach notes yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.coachName,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        note.note,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          sectionLabel('Consents pending'),
          if (consents.isEmpty)
            Text(
              'No pending consents.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final consent in consents)
              Container(
                key: ValueKey('consentRequest_${consent.id}'),
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
                      consentTypeLabels[consent.type]!,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      consent.description,
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          key: ValueKey('declineConsentButton_${consent.id}'),
                          onPressed: () => notifier.declineConsent(consent.id),
                          child: const Text('Decline'),
                        ),
                        FilledButton(
                          key: ValueKey('approveConsentButton_${consent.id}'),
                          onPressed: () => notifier.approveConsent(consent.id),
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

class _ReadOnlyStat extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          Text(
            value,
            style: AppTypography.stat.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
