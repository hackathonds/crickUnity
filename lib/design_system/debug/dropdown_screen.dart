import 'package:flutter/material.dart';

import '../components/app_dropdown_field.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 9/10): [AppDropdownField] — the plain
/// (<=8 options, no search row) and search-row (>8 options) paths.
class DropdownScreen extends StatefulWidget {
  const DropdownScreen({super.key});

  @override
  State<DropdownScreen> createState() => _DropdownScreenState();
}

class _DropdownScreenState extends State<DropdownScreen> {
  String? _format;
  String? _ground;

  static const _formats = ['T20', 'ODI', 'Test', 'T10'];
  static const _grounds = [
    'Green Park',
    'Oval Maidan',
    'City Stadium',
    'Riverside Ground',
    'Hill View Turf',
    'Central Park Pitch',
    'Lakeside Arena',
    'Sunrise Ground',
    'Community Field',
    'Eastside Turf',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
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
      appBar: AppBar(title: const Text('Dropdown-as-sheet (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('4 options — plain radio list'),
            AppDropdownField<String>(
              label: 'Format',
              value: _format,
              options: _formats,
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _format = v),
            ),
            label('10 options — search row appears'),
            AppDropdownField<String>(
              label: 'Ground',
              value: _ground,
              options: _grounds,
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _ground = v),
            ),
          ],
        ),
      ),
    );
  }
}
