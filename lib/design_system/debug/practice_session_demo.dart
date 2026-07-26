import 'package:flutter/material.dart';

import '../../teams/practice_session_screen.dart';
import '../components/app_text_field.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E3-07: pick viewer name + coach toggle -- mock session is
/// scheduled at "now" so the debug demo naturally lands inside the
/// check-in window.
class PracticeSessionDemo extends StatefulWidget {
  const PracticeSessionDemo({super.key});

  @override
  State<PracticeSessionDemo> createState() => _PracticeSessionDemoState();
}

class _PracticeSessionDemoState extends State<PracticeSessionDemo> {
  final _nameController = TextEditingController(text: 'Priya Nair');
  bool _isCoach = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice session (QA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Controls',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (sheetContext) => StatefulBuilder(
                builder: (sheetContext, setSheetState) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        key: const ValueKey('practiceSessionDemoNameField'),
                        label: 'Viewer name',
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                      ),
                      SwitchListTile(
                        key: const ValueKey('practiceSessionDemoCoachSwitch'),
                        title: const Text('Coach/captain view'),
                        value: _isCoach,
                        onChanged: (value) => setState(() {
                          setSheetState(() => _isCoach = value);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: PracticeSessionScreen(
        viewerName: _nameController.text,
        isCoach: _isCoach,
      ),
    );
  }
}
