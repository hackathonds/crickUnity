import 'package:flutter/material.dart';

import '../../teams/announcements_screen.dart';
import '../../teams/team_member_models.dart';
import '../components/app_dropdown_field.dart';
import '../components/app_text_field.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E3-05: pick acting role + viewer name (mock announcement
/// author is "Arjun Rao", so that's the default to see the author-only
/// "Seen X/Y" line) -- same "demo + controls" pattern used elsewhere.
class AnnouncementsDemo extends StatefulWidget {
  const AnnouncementsDemo({super.key});

  @override
  State<AnnouncementsDemo> createState() => _AnnouncementsDemoState();
}

class _AnnouncementsDemoState extends State<AnnouncementsDemo> {
  TeamMemberRole _role = TeamMemberRole.captain;
  final _nameController = TextEditingController(text: 'Arjun Rao');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdownField<TeamMemberRole>(
              key: const ValueKey('announcementsDemoRoleField'),
              label: 'Acting as',
              value: _role,
              options: TeamMemberRole.values,
              labelBuilder: (r) => teamMemberRoleLabels[r]!,
              onChanged: (value) => setState(() => _role = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('announcementsDemoNameField'),
              label: 'Viewer name',
              controller: _nameController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: AnnouncementsScreen(
                actingRole: _role,
                actorName: _nameController.text,
                totalMembers: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
