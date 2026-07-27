import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../academies/academy_provider.dart';
import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'coach_models.dart';
import 'coach_provider.dart';

/// DS §7.6 item 46 (Coach Console): "batch cards -> student roster
/// (progress rings 44 per student) -> session planner (template picker
/// grid from Drill Library, drill cards showing prescription) ->
/// progress-card composer (approve -> send)." Reuses the real
/// academyProvider student roster (E11-02) rather than a second
/// student list, and AppArcRing (its Nth reuse this session) for the
/// 44px progress rings.
class CoachConsoleScreen extends ConsumerStatefulWidget {
  const CoachConsoleScreen({super.key});

  @override
  ConsumerState<CoachConsoleScreen> createState() => _CoachConsoleScreenState();
}

class _CoachConsoleScreenState extends ConsumerState<CoachConsoleScreen> {
  String? _selectedStudentName;
  String? _selectedTemplateId;
  AgeBand _ageBand = AgeBand.adult;
  DateTime? _sessionDate;
  String? _assignError;
  final _progressNotesController = TextEditingController();

  @override
  void dispose() {
    _progressNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final students = ref.watch(academyProvider).students;
    final coachState = ref.watch(coachProvider);
    final coachNotifier = ref.read(coachProvider.notifier);

    if (_selectedStudentName == null && students.isNotEmpty) {
      _selectedStudentName = students.first.name;
    }
    if (_selectedTemplateId == null && coachState.templates.isNotEmpty) {
      _selectedTemplateId = coachState.templates.first.id;
    }
    final template = coachState.templates
        .where((t) => t.id == _selectedTemplateId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Coach console')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Student roster', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final student in students)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AppArcRing(
                              progress:
                                  (coachState
                                              .sessionsThisWeekFor(
                                                student.name,
                                                DateTime.now(),
                                              )
                                              .length /
                                          maxSessionsPerWeek)
                                      .clamp(0.0, 1.0),
                              size: 44,
                              strokeWidth: 4,
                              trackColor: colors.border,
                              fillColor: colors.primary,
                            ),
                            Text(
                              '${coachState.sessionsThisWeekFor(student.name, DateTime.now()).length}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(student.name, style: AppTypography.caption),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Session planner', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final student in students)
                ChoiceChip(
                  key: ValueKey('plannerStudentChip_${student.id}'),
                  label: Text(student.name),
                  selected: _selectedStudentName == student.name,
                  onSelected: (_) =>
                      setState(() => _selectedStudentName = student.name),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in coachState.templates)
                ChoiceChip(
                  key: ValueKey('templateChip_${t.id}'),
                  label: Text(t.name),
                  selected: _selectedTemplateId == t.id,
                  onSelected: (_) => setState(() => _selectedTemplateId = t.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Age band (autoscales prescription)',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final band in AgeBand.values)
                ChoiceChip(
                  key: ValueKey('ageBandChip_${band.name}'),
                  label: Text(ageBandLabels[band]!),
                  selected: _ageBand == band,
                  onSelected: (_) => setState(() => _ageBand = band),
                ),
            ],
          ),
          if (template != null) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final drillId in template.drillIds)
              Builder(
                builder: (context) {
                  final drill = coachState.drills.firstWhere(
                    (d) => d.id == drillId,
                  );
                  final (sets, reps) = scaledPrescription(drill, _ageBand);
                  return Container(
                    key: ValueKey('drillCard_${drill.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${drill.name} (${drillCategoryLabels[drill.category]}) -- $sets sets x $reps reps',
                      style: AppTypography.body,
                    ),
                  );
                },
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _sessionDate = picked);
            },
            child: Text(
              _sessionDate == null
                  ? 'Pick session date'
                  : '${_sessionDate!.day}/${_sessionDate!.month}/${_sessionDate!.year}',
            ),
          ),
          if (_assignError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                _assignError!,
                style: AppTypography.caption.copyWith(color: colors.error),
              ),
            ),
          AppButton(
            key: const ValueKey('assignSessionButton'),
            variant: AppButtonVariant.primary,
            label: 'Assign session',
            fullWidth: true,
            onPressed:
                _selectedStudentName == null ||
                    _selectedTemplateId == null ||
                    _sessionDate == null
                ? null
                : () {
                    final error = coachNotifier.assignSession(
                      _selectedStudentName!,
                      _selectedTemplateId!,
                      _sessionDate!,
                    );
                    setState(() {
                      _assignError = error;
                      if (error == null) _sessionDate = null;
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Drill personal bests', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          // A simple value list stands in for a real chart -- hand-
          // rolled charting is deferred to E13-01 (Chart library
          // completion), same convention flagged elsewhere this
          // session for out-of-proportion visualization asks.
          if (_selectedStudentName != null && template != null)
            for (final drillId in template.drillIds)
              Builder(
                builder: (context) {
                  final pbs = coachState.personalBestsFor(
                    _selectedStudentName!,
                    drillId,
                  );
                  final drill = coachState.drills.firstWhere(
                    (d) => d.id == drillId,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${drill.name}: ${pbs.map((p) => p.value).join(' -> ')}',
                            style: AppTypography.body.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          key: ValueKey('recordPbButton_$drillId'),
                          onPressed: () => coachNotifier.recordPersonalBest(
                            _selectedStudentName!,
                            drillId,
                            (pbs.isEmpty ? 10 : pbs.last.value) + 1,
                          ),
                          child: const Text('+1 PB (debug)'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          const SizedBox(height: AppSpacing.xl),
          Text('Monthly progress card', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _progressNotesController,
            decoration: const InputDecoration(labelText: 'Progress notes'),
            maxLines: 3,
          ),
          AppButton(
            key: const ValueKey('composeProgressCardButton'),
            variant: AppButtonVariant.secondary,
            label: 'Compose progress card',
            fullWidth: true,
            onPressed:
                _selectedStudentName == null ||
                    _progressNotesController.text.trim().isEmpty
                ? null
                : () {
                    coachNotifier.composeProgressCard(
                      _selectedStudentName!,
                      '${DateTime.now().month}/${DateTime.now().year}',
                      _progressNotesController.text.trim(),
                    );
                    _progressNotesController.clear();
                    setState(() {});
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final card in coachState.progressCards)
            Container(
              key: ValueKey('progressCardRow_${card.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${card.studentName} -- ${card.monthLabel}',
                          style: AppTypography.body,
                        ),
                        Text(
                          card.notes,
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (card.approved)
                    Text(
                      'Sent',
                      style: AppTypography.caption.copyWith(
                        color: colors.success,
                      ),
                    )
                  else
                    TextButton(
                      key: ValueKey('approveSendButton_${card.id}'),
                      onPressed: () => coachNotifier.approveAndSend(card.id),
                      child: const Text('Approve & send'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
