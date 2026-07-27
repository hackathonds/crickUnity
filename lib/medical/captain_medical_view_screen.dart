import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'medical_models.dart';
import 'medical_provider.dart';

/// DS §11.16: "captain's event-day view: roster menu -> Medical (only
/// within window, view-only, watermarked 'visible during event')." No
/// real match-event-window clock exists to gate this against -- a
/// toggleable "within event window" QA flag stands in, same convention
/// as every other missing-real-time-context gap this session.
class CaptainMedicalViewScreen extends ConsumerStatefulWidget {
  final String playerName;
  final String teamName;

  const CaptainMedicalViewScreen({
    super.key,
    required this.playerName,
    required this.teamName,
  });

  @override
  ConsumerState<CaptainMedicalViewScreen> createState() =>
      _CaptainMedicalViewScreenState();
}

class _CaptainMedicalViewScreenState
    extends ConsumerState<CaptainMedicalViewScreen> {
  bool _withinEventWindow = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final card = ref.watch(medicalProvider).card;
    final revealed = card.teamRevealToggles[widget.teamName] ?? false;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.playerName} -- Medical')),
      body: Column(
        children: [
          SwitchListTile(
            key: const ValueKey('withinEventWindowSwitch'),
            title: const Text('Within event window (QA)'),
            value: _withinEventWindow,
            onChanged: (v) => setState(() => _withinEventWindow = v),
          ),
          Expanded(
            child: !_withinEventWindow
                ? Center(
                    child: Text(
                      'Only visible during a live event window.',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : !revealed
                ? Center(
                    child: Text(
                      '${widget.playerName} hasn\'t enabled reveal for '
                      '${widget.teamName}.',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          _InfoRow(
                            label: 'Blood group',
                            value: card.bloodGroup == null
                                ? '-'
                                : bloodGroupLabels[card.bloodGroup]!,
                          ),
                          _InfoRow(
                            label: 'Allergies',
                            value: card.allergies.isEmpty
                                ? 'None'
                                : card.allergies.join(', '),
                          ),
                          _InfoRow(
                            label: 'Conditions',
                            value: card.conditions.isEmpty
                                ? 'None'
                                : card.conditions.join(', '),
                          ),
                          _InfoRow(
                            label: 'Emergency contact',
                            value:
                                '${card.emergencyContactName} '
                                '${card.emergencyContactPhone}',
                          ),
                        ],
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.4,
                            child: Opacity(
                              opacity: 0.15,
                              child: Text(
                                'VISIBLE DURING EVENT',
                                key: const ValueKey('medicalWatermarkText'),
                                style: AppTypography.h1.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
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
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
