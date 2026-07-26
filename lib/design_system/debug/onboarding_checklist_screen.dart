import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/onboarding_checklist_provider.dart';
import '../../home/onboarding_checklist_widget.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E1-05: [OnboardingChecklistWidget], with independent
/// toggles for the 3 items that have no real event source yet
/// (Team/Match/Expense features are later epics). "Complete profile" is
/// driven by profileWizardProvider (E1-03) instead, same as the real Home
/// wiring.
class OnboardingChecklistScreen extends ConsumerWidget {
  const OnboardingChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingChecklistProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding checklist (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingChecklistWidget(),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: const ValueKey('checklistDebugJoinTeam'),
                  onPressed: () =>
                      notifier.completeItem(ChecklistItem.joinOrCreateTeam),
                  child: const Text('Join a team'),
                ),
                OutlinedButton(
                  key: const ValueKey('checklistDebugPlayMatch'),
                  onPressed: () =>
                      notifier.completeItem(ChecklistItem.playFirstMatch),
                  child: const Text('Play first match'),
                ),
                OutlinedButton(
                  key: const ValueKey('checklistDebugSettleExpense'),
                  onPressed: () =>
                      notifier.completeItem(ChecklistItem.settleFirstExpense),
                  child: const Text('Settle first expense'),
                ),
                OutlinedButton(
                  onPressed: notifier.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
