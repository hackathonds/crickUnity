import 'package:flutter/material.dart';

import 'avatar_screen.dart';
import 'buttons_screen.dart';
import 'card_screen.dart';
import 'chips_screen.dart';
import 'forms_kit_screen.dart';
import 'icon_gallery_screen.dart';
import 'sheet_dialog_snackbar_screen.dart';
import 'search_bar_screen.dart';
import 'segmented_control_screen.dart';
import 'shell_debug_screen.dart';
import 'state_scaffolds_screen.dart';
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
          ListTile(
            title: const Text('State scaffolds'),
            subtitle: const Text(
              'E0-06 — empty/loading/error/offline, queued actions',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StateScaffoldsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Buttons'),
            subtitle: const Text(
              'E0-07 (1/10) — primary/secondary/tertiary/destructive, chip, icon, FAB',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ButtonsScreen())),
          ),
          ListTile(
            title: const Text('Cards'),
            subtitle: const Text(
              'E0-07 (2/10) — base card, header/menu, money surface, loading',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CardScreen())),
          ),
          ListTile(
            title: const Text('Search bar'),
            subtitle: const Text(
              'E0-07 (3/10) — pill, expansion, recent list, voice, QR hook',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchBarScreen())),
          ),
          ListTile(
            title: const Text('Segmented control'),
            subtitle: const Text(
              'E0-07 (4/10) — sliding track, scrollable-chip-row fallback',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SegmentedControlScreen()),
            ),
          ),
          ListTile(
            title: const Text('Chips'),
            subtitle: const Text(
              'E0-07 (5/10) — static tag/status chips, delta chip',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChipsScreen())),
          ),
          ListTile(
            title: const Text('Avatars'),
            subtitle: const Text(
              'E0-07 (6/10) — sizes, level ring, presence, verified badge',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AvatarScreen())),
          ),
          ListTile(
            title: const Text('Forms kit'),
            subtitle: const Text(
              'E0-07 (7/10) — floating label field, currency field, step progress',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FormsKitScreen())),
          ),
        ],
      ),
    );
  }
}
