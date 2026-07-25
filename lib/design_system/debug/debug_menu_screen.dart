import 'package:flutter/material.dart';

import 'icon_gallery_screen.dart';
import 'type_specimen_screen.dart';

/// Lists the internal QA screens built up across the E0 stories so far.
/// Exists only because there's no real navigation shell yet (E0-04) —
/// replaced by it once that story lands.
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
        ],
      ),
    );
  }
}
