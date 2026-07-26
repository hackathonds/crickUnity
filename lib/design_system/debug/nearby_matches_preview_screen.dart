import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/nearby_matches_preview_card.dart';
import '../../onboarding/permissions_provider.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E1-03's AC: "denial of location makes Nearby widget show
/// its enable-prompt state" (PRD §4.11). The real Home dashboard doesn't
/// exist yet -- see [NearbyMatchesPreviewCard]'s own doc comment.
class NearbyMatchesPreviewScreen extends ConsumerWidget {
  const NearbyMatchesPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(permissionsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby matches (QA preview)')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NearbyMatchesPreviewCard(),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton(
              onPressed: () => notifier.setLocation(PermissionStatus.denied),
              child: const Text('Simulate location denied'),
            ),
          ],
        ),
      ),
    );
  }
}
