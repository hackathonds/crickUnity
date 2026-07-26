import 'package:flutter/material.dart';

import '../../teams/jersey_board_screen.dart';
import '../components/app_text_field.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E3-09: pick viewer name + manager toggle -- same
/// "demo + controls" pattern used elsewhere.
class JerseyBoardDemo extends StatefulWidget {
  const JerseyBoardDemo({super.key});

  @override
  State<JerseyBoardDemo> createState() => _JerseyBoardDemoState();
}

class _JerseyBoardDemoState extends State<JerseyBoardDemo> {
  final _nameController = TextEditingController(text: 'Arjun Rao');
  bool _isManager = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jersey board (QA)'),
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
                        key: const ValueKey('jerseyBoardDemoNameField'),
                        label: 'Viewer name',
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                      ),
                      SwitchListTile(
                        key: const ValueKey('jerseyBoardDemoManagerSwitch'),
                        title: const Text('Manager view'),
                        value: _isManager,
                        onChanged: (value) => setState(() {
                          setSheetState(() => _isManager = value);
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
      body: JerseyBoardScreen(
        viewerName: _nameController.text,
        isManager: _isManager,
      ),
    );
  }
}
