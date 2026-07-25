import 'package:flutter/material.dart';

import 'icon_gallery_screen.dart';
import 'sheet_dialog_snackbar_screen.dart';
import 'shell_debug_screen.dart';
import 'type_specimen_screen.dart';

/// Lists the internal QA screens built up across the E0 stories so far.
/// Since E0-04, the app's real home is the navigation shell — this menu is
/// reached via a temporary link on the Profile tab instead of being the
/// app's `home`.
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design system QA')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Type specimen'),
            subtitle: const Text('E0-02 — every type role'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TypeSpecimenScreen()),
            ),
          ),
          ListTile(
            title: const Text('Icon gallery'),
            subtitle: const Text('E0-03 — every icon family'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IconGalleryScreen()),
            ),
          ),
          ListTile(
            title: const Text('Shell debug controls'),
            subtitle: const Text('E0-04 — roles, badges, pinned live match'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ShellDebugScreen())),
          ),
          ListTile(
            title: const Text('Sheet / dialog / snackbar'),
            subtitle: const Text('E0-05 — bottom sheet, dialogs, snackbar'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SheetDialogSnackbarScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
