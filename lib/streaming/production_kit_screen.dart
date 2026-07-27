import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../officials/commentator_room_provider.dart';
import 'go_live_models.dart';
import 'go_live_provider.dart';
import 'production_kit_models.dart';
import 'production_kit_provider.dart';

/// DS §11.8: "Production kit screen (organizer): overlay theme gallery,
/// lower-third editor (text fields with live preview strip), destination
/// checklist, commentator-assign row." See production_kit_provider.dart's
/// top-of-file note on why overlay theme and commentator assignment
/// reuse other stories' providers instead of duplicating state.
class ProductionKitScreen extends ConsumerWidget {
  const ProductionKitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final goLive = ref.watch(goLiveProvider);
    final goLiveNotifier = ref.read(goLiveProvider.notifier);
    final kit = ref.watch(productionKitProvider);
    final kitNotifier = ref.read(productionKitProvider.notifier);
    final commentatorAssigned = ref.watch(
      commentatorRoomProvider.select((s) => s.isAssigned),
    );

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
      appBar: AppBar(title: const Text('Production kit')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sectionLabel('Overlay theme'),
          Row(
            children: [
              for (final theme in OverlayTheme.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      key: ValueKey('productionKitThemeThumb_${theme.name}'),
                      onTap: () => goLiveNotifier.selectOverlayTheme(theme),
                      child: Container(
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: goLive.overlayTheme == theme
                                ? colors.primary
                                : colors.border,
                            width: goLive.overlayTheme == theme ? 2 : 1,
                          ),
                        ),
                        child: Text(overlayThemeLabels[theme]!),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          sectionLabel('Lower-third'),
          TextField(
            key: const ValueKey('lowerThirdTopField'),
            decoration: const InputDecoration(labelText: 'Top text'),
            onChanged: kitNotifier.setLowerThirdTopText,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('lowerThirdBottomField'),
            decoration: const InputDecoration(labelText: 'Bottom text'),
            onChanged: kitNotifier.setLowerThirdBottomText,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            key: const ValueKey('lowerThirdLivePreview'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.textPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kit.lowerThird.topText.isEmpty ? ' ' : kit.lowerThird.topText,
                  style: AppTypography.subtitle.copyWith(color: colors.surface),
                ),
                Text(
                  kit.lowerThird.bottomText.isEmpty
                      ? ' '
                      : kit.lowerThird.bottomText,
                  style: AppTypography.caption.copyWith(color: colors.surface),
                ),
              ],
            ),
          ),
          sectionLabel('Destinations'),
          for (final destination in StreamDestination.values)
            CheckboxListTile(
              key: ValueKey('destinationCheckbox_${destination.name}'),
              value: kit.destinations.contains(destination),
              onChanged: (_) => kitNotifier.toggleDestination(destination),
              title: Text(streamDestinationLabels[destination]!),
            ),
          sectionLabel('Commentator'),
          Row(
            children: [
              Expanded(
                child: Text(
                  commentatorAssigned
                      ? 'Commentator assigned'
                      : 'No commentator assigned',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Switch(
                key: const ValueKey('commentatorAssignSwitch'),
                value: commentatorAssigned,
                onChanged: (v) =>
                    ref.read(commentatorRoomProvider.notifier).setAssigned(v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
