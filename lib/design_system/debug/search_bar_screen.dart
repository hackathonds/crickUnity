import 'package:flutter/material.dart';

import '../components/app_search_bar.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 3/10): the search bar pill, its full-width
/// expansion, recent searches, voice waveform affordance, and QR hook.
class SearchBarScreen extends StatefulWidget {
  const SearchBarScreen({super.key});

  @override
  State<SearchBarScreen> createState() => _SearchBarScreenState();
}

class _SearchBarScreenState extends State<SearchBarScreen> {
  String? _lastSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Search bar (QA)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              hintText: 'Search players, teams, grounds...',
              recentSearches: const [
                'Titans CC',
                'Green Park Turf',
                'Deepak Sharma',
              ],
              onSubmit: (value) => setState(() => _lastSubmitted = value),
              onQrTap: () => setState(() => _lastSubmitted = '(QR tapped)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_lastSubmitted != null)
              Text(
                'Last submitted: $_lastSubmitted',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}
