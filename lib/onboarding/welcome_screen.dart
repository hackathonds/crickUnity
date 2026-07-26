import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

class _WelcomeSlide {
  final String title;
  final String subtitle;

  const _WelcomeSlide({required this.title, required this.subtitle});
}

const List<_WelcomeSlide> _slides = [
  _WelcomeSlide(
    title: 'Your career, verified',
    subtitle:
        'Every run, wicket, and catch backed by a scorecard your teammates '
        'confirmed.',
  ),
  _WelcomeSlide(
    title: 'Money made simple',
    subtitle: 'Split match fees and ground costs without the group-chat maths.',
  ),
  _WelcomeSlide(
    title: 'Rewards for showing up',
    subtitle: 'Coins, badges, and titles for the cricket you already play.',
  ),
];

/// DS §11.3 Welcome: "3-slide value pager (verified career · money made
/// simple · rewards), Arc page dots, [Get started] sticky + [Explore first]
/// tertiary -> Guest." PRD §20-A1 offline note: "cached slides" -- this
/// content is static/bundled, not fetched, so there's nothing to cache.
///
/// Navigation is the caller's concern (same "expose a callback" scope
/// boundary used throughout E0-08): [onGetStarted] should lead to
/// Registration (this story); [onExploreAsGuest] should lead to Guest mode
/// (E1-04, not built yet).
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onExploreAsGuest;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onExploreAsGuest,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final duration = AppMotion.resolveDuration(
      context,
      AppMotionToken.standard,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                key: const ValueKey('welcomeScreenPager'),
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final slide in _slides)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppArcIllustration(color: colors.primary),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.h1.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              key: const ValueKey('welcomeScreenPageDots'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: duration,
                    curve: AppMotionCurves.standard,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? colors.primary : colors.divider,
                      borderRadius: AppRadius.fullRadius,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  AppButton(
                    variant: AppButtonVariant.primary,
                    label: 'Get started',
                    fullWidth: true,
                    onPressed: widget.onGetStarted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    variant: AppButtonVariant.tertiary,
                    label: 'Explore first',
                    fullWidth: true,
                    onPressed: widget.onExploreAsGuest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
