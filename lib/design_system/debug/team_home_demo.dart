import 'package:flutter/material.dart';

import '../../teams/team_home_screen.dart';
import '../../teams/team_models.dart';
import '../../teams/team_viewer_role.dart';
import '../components/app_dropdown_field.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E3-02: every [TeamViewerRole] x archived-state combination
/// the AC calls out, same "demo + controls sheet" pattern as
/// profile_screen_demo.dart.
class TeamHomeDemo extends StatefulWidget {
  const TeamHomeDemo({super.key});

  @override
  State<TeamHomeDemo> createState() => _TeamHomeDemoState();
}

class _TeamHomeDemoState extends State<TeamHomeDemo> {
  TeamViewerRole _role = TeamViewerRole.owner;
  bool _isArchived = false;

  @override
  Widget build(BuildContext context) {
    final base = mockTeam();
    final team = Team(
      name: base.name,
      city: base.city,
      homeGround: base.homeGround,
      formatFocus: base.formatFocus,
      joinPolicy: base.joinPolicy,
      primaryColor: base.primaryColor,
      secondaryColor: base.secondaryColor,
      followerCount: base.followerCount,
      memberCount: base.memberCount,
      isArchived: _isArchived,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team home (QA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Controls',
            onPressed: () => _openControls(context),
          ),
        ],
      ),
      body: TeamHomeScreen(team: team, viewerRole: _role),
    );
  }

  void _openControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdownField<TeamViewerRole>(
                key: const ValueKey('teamHomeDemoRoleField'),
                label: 'Viewer role',
                value: _role,
                options: TeamViewerRole.values,
                labelBuilder: (r) => r.name,
                onChanged: (value) => setState(() {
                  setSheetState(() => _role = value);
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                key: const ValueKey('teamHomeDemoArchivedSwitch'),
                title: const Text('Archived'),
                value: _isArchived,
                onChanged: (value) => setState(() {
                  setSheetState(() => _isArchived = value);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
