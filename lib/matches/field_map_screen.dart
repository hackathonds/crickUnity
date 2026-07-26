import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'field_map_models.dart';
import 'field_map_provider.dart';

const double _tokenSize = 32;

/// DS §11.7: "Field map tool (captain, from Match overflow): drag 11
/// fielder tokens 32 on oval; phase presets save slots; team-private
/// badge."
class FieldMapScreen extends ConsumerWidget {
  const FieldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(fieldMapProvider);
    final notifier = ref.read(fieldMapProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Field map')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              key: const ValueKey('teamPrivateBadge'),
              label: const Text('Team-private'),
              avatar: const Icon(Icons.lock, size: 16),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  return Stack(
                    key: const ValueKey('fieldMapOval'),
                    children: [
                      CustomPaint(
                        size: Size(width, height),
                        painter: _OvalGroundPainter(
                          groundColor: colors.surfaceAlt,
                          pitchColor: colors.border,
                        ),
                      ),
                      for (final position in state.positions)
                        Positioned(
                          left: position.x * width - _tokenSize / 2,
                          top: position.y * height - _tokenSize / 2,
                          child: GestureDetector(
                            key: ValueKey(
                              'fielderToken_${position.fielderName}',
                            ),
                            onPanUpdate: (details) => notifier.moveFielder(
                              position.fielderName,
                              position.x + details.delta.dx / width,
                              position.y + details.delta.dy / height,
                            ),
                            child: Container(
                              width: _tokenSize,
                              height: _tokenSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
                              ),
                              child: Text(
                                _initials(position.fielderName),
                                style: AppTypography.caption.copyWith(
                                  color: colors.surface,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Phase presets',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final slot in fieldMapPresetSlots)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    AppButton(
                      key: ValueKey('savePreset_$slot'),
                      variant: AppButtonVariant.secondary,
                      label: 'Save',
                      onPressed: () => notifier.savePreset(slot),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      key: ValueKey('loadPreset_$slot'),
                      variant: AppButtonVariant.tertiary,
                      label: 'Load',
                      onPressed: state.presets.containsKey(slot)
                          ? () => notifier.loadPreset(slot)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length < 2) return name.substring(0, 2);
    return '${parts[0][0]}${parts[1][0]}';
  }
}

class _OvalGroundPainter extends CustomPainter {
  final Color groundColor;
  final Color pitchColor;

  const _OvalGroundPainter({
    required this.groundColor,
    required this.pitchColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundPaint = Paint()..color = groundColor;
    canvas.drawOval(Offset.zero & size, groundPaint);

    final pitchPaint = Paint()..color = pitchColor;
    final pitchRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.08,
      height: size.height * 0.5,
    );
    canvas.drawRect(pitchRect, pitchPaint);
  }

  @override
  bool shouldRepaint(covariant _OvalGroundPainter oldDelegate) =>
      groundColor != oldDelegate.groundColor ||
      pitchColor != oldDelegate.pitchColor;
}
