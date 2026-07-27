import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'medical_models.dart';
import 'medical_provider.dart';

const List<String> _mockPlayerTeams = ['Strikers CC', 'City Titans'];

/// DS §11.16: "Medical & emergency card: Profile -> private section;
/// form (blood group select, allergies tags, conditions, emergency
/// contact); consent screen states exactly who sees it and when
/// (event-window reveal), toggle per team."
class MedicalCardScreen extends ConsumerWidget {
  const MedicalCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(medicalProvider);
    final notifier = ref.read(medicalProvider.notifier);
    final card = state.card;

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
      appBar: AppBar(title: const Text('Medical & emergency card')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Private -- only visible to you, and to team captains during '
              'a live event window if you enable reveal below.',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          sectionLabel('Blood group'),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final group in BloodGroup.values)
                ChoiceChip(
                  key: ValueKey('bloodGroupChip_${group.name}'),
                  label: Text(bloodGroupLabels[group]!),
                  selected: card.bloodGroup == group,
                  onSelected: (_) => notifier.updateCard(bloodGroup: group),
                ),
            ],
          ),
          sectionLabel('Allergies'),
          _TagEditor(
            key: const ValueKey('allergiesTagEditor'),
            tags: card.allergies,
            onChanged: (tags) => notifier.updateCard(allergies: tags),
          ),
          sectionLabel('Conditions'),
          _TagEditor(
            key: const ValueKey('conditionsTagEditor'),
            tags: card.conditions,
            onChanged: (tags) => notifier.updateCard(conditions: tags),
          ),
          sectionLabel('Emergency contact'),
          TextField(
            key: const ValueKey('emergencyContactNameField'),
            decoration: const InputDecoration(labelText: 'Name'),
            controller: TextEditingController(text: card.emergencyContactName),
            onChanged: (v) => notifier.updateCard(emergencyContactName: v),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('emergencyContactPhoneField'),
            decoration: const InputDecoration(labelText: 'Phone'),
            controller: TextEditingController(text: card.emergencyContactPhone),
            onChanged: (v) => notifier.updateCard(emergencyContactPhone: v),
          ),
          sectionLabel('Reveal per team (event-window only)'),
          for (final team in _mockPlayerTeams)
            SwitchListTile(
              key: ValueKey('teamRevealSwitch_$team'),
              contentPadding: EdgeInsets.zero,
              title: Text(team),
              subtitle: const Text(
                'Captain can view during a live event, watermarked',
              ),
              value: card.teamRevealToggles[team] ?? false,
              onChanged: (v) => notifier.setTeamReveal(team, v),
            ),
        ],
      ),
    );
  }
}

class _TagEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const _TagEditor({super.key, required this.tags, required this.onChanged});

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onChanged([...widget.tags, value]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final tag in widget.tags)
              InputChip(
                key: ValueKey('tag_$tag'),
                label: Text(tag),
                onDeleted: () => widget.onChanged(
                  widget.tags.where((t) => t != tag).toList(),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(hintText: 'Add...'),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _add),
          ],
        ),
      ],
    );
  }
}
