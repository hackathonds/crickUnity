import 'package:flutter/material.dart';

import '../components/app_avatar.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-07 (sub-task 6/10): [AppAvatar] — sizes, level ring,
/// presence dot, verified badge.
class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Avatars (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Sizes 24/32/40/48/64/96 — initials fallback'),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                AppAvatar(size: AppAvatarSize.xs, name: 'Deepak Sharma'),
                AppAvatar(size: AppAvatarSize.sm, name: 'Ritika Iyer'),
                AppAvatar(size: AppAvatarSize.md, name: 'Naveen Kumar'),
                AppAvatar(size: AppAvatarSize.lg, name: 'Priya Nair'),
                AppAvatar(size: AppAvatarSize.xl, name: 'Arjun Rao'),
                AppAvatar(size: AppAvatarSize.xxl, name: 'Simran Kaur'),
              ],
            ),
            label('Level ring (md/lg/xl) — only paints at 40px+'),
            const Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                AppAvatar(
                  size: AppAvatarSize.md,
                  name: 'Naveen Kumar',
                  levelProgress: 0.3,
                ),
                AppAvatar(
                  size: AppAvatarSize.lg,
                  name: 'Priya Nair',
                  levelProgress: 0.65,
                ),
                AppAvatar(
                  size: AppAvatarSize.xl,
                  name: 'Arjun Rao',
                  levelProgress: 0.9,
                ),
              ],
            ),
            label('Presence dot — online / away'),
            const Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                AppAvatar(
                  size: AppAvatarSize.lg,
                  name: 'Priya Nair',
                  presence: AppPresenceStatus.online,
                ),
                AppAvatar(
                  size: AppAvatarSize.lg,
                  name: 'Arjun Rao',
                  presence: AppPresenceStatus.away,
                ),
              ],
            ),
            label('Verified badge — only at 48px+'),
            const Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                AppAvatar(
                  size: AppAvatarSize.lg,
                  name: 'Priya Nair',
                  verified: true,
                ),
                AppAvatar(
                  size: AppAvatarSize.xl,
                  name: 'Arjun Rao',
                  levelProgress: 0.5,
                  verified: true,
                ),
                AppAvatar(
                  size: AppAvatarSize.xxl,
                  name: 'Simran Kaur',
                  levelProgress: 0.8,
                  presence: AppPresenceStatus.online,
                  verified: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
