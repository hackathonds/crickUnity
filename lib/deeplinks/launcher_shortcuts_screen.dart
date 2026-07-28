import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../expenses/add_edit_expense_screen.dart';
import '../matches/live_scoring_console_screen.dart';
import '../matches/match_detail_screen.dart';
import '../matches/matches_provider.dart';
import '../search/qr_scanner_screen.dart';
import '../social/composer_screen.dart' show composerViewerName;
import 'deep_link_models.dart';

/// DS §1.3: "Launcher shortcuts (long-press app icon): Start Scoring /
/// My Next Match / Scan QR / Add Expense." No quick_actions package
/// exists in this project (pubspec.yaml has none) -- real long-press
/// home-screen shortcuts need native platform registration a Flutter
/// Dart-only session can't configure. This in-app stand-in navigates to
/// the same real destinations those OS shortcuts would.
class LauncherShortcutsScreen extends ConsumerWidget {
  const LauncherShortcutsScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, LauncherShortcut shortcut) {
    switch (shortcut) {
      case LauncherShortcut.startScoring:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LiveScoringConsoleScreen()),
        );
      case LauncherShortcut.myNextMatch:
        final matches = ref.read(matchesProvider).matches;
        if (matches.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No upcoming matches.')));
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchDetailScreen(
              matchId: matches.first.id,
              viewerName: composerViewerName,
              isCaptain: true,
            ),
          ),
        );
      case LauncherShortcut.scanQr:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
      case LauncherShortcut.addExpense:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddEditExpenseScreen(
              viewerName: composerViewerName,
              viewerIsCaptain: true,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Launcher shortcuts (demo)')),
      body: ListView(
        children: [
          for (final shortcut in LauncherShortcut.values)
            ListTile(
              key: ValueKey('launcherShortcut_${shortcut.name}'),
              title: Text(launcherShortcutLabels[shortcut]!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, ref, shortcut),
            ),
        ],
      ),
    );
  }
}
