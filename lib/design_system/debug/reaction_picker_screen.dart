import 'package:flutter/material.dart';

import '../components/app_reaction_picker.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 8/12): [AppReactionBar] -- quick-tap
/// default clap, long-press-drag-release radial picker, particle burst,
/// counts pill.
class ReactionPickerScreen extends StatefulWidget {
  const ReactionPickerScreen({super.key});

  @override
  State<ReactionPickerScreen> createState() => _ReactionPickerScreenState();
}

class _ReactionPickerScreenState extends State<ReactionPickerScreen> {
  int _count = 12;
  AppReactionType? _mine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Reaction arc-picker (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tap = default clap. Long-press, drag over a reaction, '
              'release to pick.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppReactionBar(
              reactionCount: _count,
              myReaction: _mine,
              onReact: (type) => setState(() {
                _mine = type;
                _count++;
              }),
              onCountsTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Breakdown sheet'))),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Match won vs Strikers! 🏏',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
