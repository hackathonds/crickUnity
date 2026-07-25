import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_money_text.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Internal QA tool rendering every DS §2.4 type role, per E0-02's AC — not
/// a product screen (see PR notes on why the 7-states rule doesn't apply
/// here). Lets design/QA sign off on the ramp, the money composition, and
/// dynamic-type reflow before any real screens are built on top of it.
class TypeSpecimenScreen extends StatefulWidget {
  const TypeSpecimenScreen({super.key});

  @override
  State<TypeSpecimenScreen> createState() => _TypeSpecimenScreenState();
}

class _TypeSpecimenScreenState extends State<TypeSpecimenScreen> {
  bool _scaledUp = false;

  static const _roles = <(String, TextStyle)>[
    ('Display', AppTypography.display),
    ('H1', AppTypography.h1),
    ('H2', AppTypography.h2),
    ('Title', AppTypography.title),
    ('Subtitle', AppTypography.subtitle),
    ('Body', AppTypography.body),
    ('Caption', AppTypography.caption),
    ('Label', AppTypography.label),
    ('Button', AppTypography.button),
    ('Stat', AppTypography.stat),
    ('Scoreboard', AppTypography.scoreboard),
  ];

  static const _tabularSamples = ['1', '22', '333', '4,444'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          _scaledUp ? AppTypography.maxTextScaleFactor : 1.0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Type specimen (QA)')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SwitchListTile(
              title: const Text('Preview at 135% dynamic type'),
              value: _scaledUp,
              onChanged: (value) => setState(() => _scaledUp = value),
            ),
            const SizedBox(height: AppSpacing.xxl),
            for (final role in _roles) ...[
              Text(
                role.$1,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                'The quick brown fox 0123456789',
                style: role.$2.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
            Text(
              'Money',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final sample in _tabularSamples) ...[
              AppMoneyText(
                symbol: '₹',
                amount: sample,
                color: colors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Tabular alignment (Stat)',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final sample in _tabularSamples)
              Text(
                sample,
                style: AppTypography.stat.copyWith(color: colors.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}
