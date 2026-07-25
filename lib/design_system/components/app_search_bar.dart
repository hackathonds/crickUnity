import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.6: 44h, r-full, `surfaceAlt` fill, leading search icon 20,
/// trailing mic 20 + QR 20 (20 gap). Tapping opens a full-width "search
/// active" experience — DS: "Focus expands to full-width app-bar
/// replacement (240ms), recent list slides up."
///
/// No real speech-to-text or QR camera scanning exists yet (those are
/// Epic E12 stories) — the mic affordance shows a waveform + an editable
/// text field the user types into themselves, and `onQrTap` is a bare hook
/// for a future scanner to wire up.
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final List<String> recentSearches;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String>? onRecentTap;
  final VoidCallback? onQrTap;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onSubmit,
    this.recentSearches = const [],
    this.onRecentTap,
    this.onQrTap,
  });

  Future<void> _openSearch(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        transitionDuration: AppMotionDuration.standard,
        reverseTransitionDuration: AppMotionDuration.standard,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _AppSearchActiveScreen(
              hintText: hintText,
              recentSearches: recentSearches,
              onRecentTap: onRecentTap,
              onQrTap: onQrTap,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (AppMotion.isReduced(context)) {
            return FadeTransition(opacity: animation, child: child);
          }
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppMotionCurves.standard,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSubmit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      key: const ValueKey('appSearchBarPill'),
      onTap: () => _openSearch(context),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: AppRadius.fullRadius,
        ),
        child: Row(
          children: [
            AppIcon(
              id: AppIconId.search,
              semanticLabel: 'Search',
              size: 20,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hintText,
                style: AppTypography.body.copyWith(color: colors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppIcon(
              id: AppIconId.mic,
              semanticLabel: 'Search by voice',
              size: 20,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            AppIcon(
              id: AppIconId.qrCode,
              semanticLabel: 'Search by QR code',
              size: 20,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSearchActiveScreen extends StatefulWidget {
  final String hintText;
  final List<String> recentSearches;
  final ValueChanged<String>? onRecentTap;
  final VoidCallback? onQrTap;

  const _AppSearchActiveScreen({
    required this.hintText,
    required this.recentSearches,
    this.onRecentTap,
    this.onQrTap,
  });

  @override
  State<_AppSearchActiveScreen> createState() => _AppSearchActiveScreenState();
}

class _AppSearchActiveScreenState extends State<_AppSearchActiveScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _listeningToVoice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('appSearchBackButton'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: AppIcon(
                      id: AppIconId.backArrow,
                      semanticLabel: 'Back',
                      color: colors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: AppRadius.fullRadius,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('appSearchTextField'),
                              controller: _controller,
                              focusNode: _focusNode,
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                                hintStyle: AppTypography.body.copyWith(
                                  color: colors.textTertiary,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                              onSubmitted: _submit,
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              key: const ValueKey('appSearchClearButton'),
                              onTap: () => setState(_controller.clear),
                              child: AppIcon(
                                id: AppIconId.close,
                                semanticLabel: 'Clear',
                                size: 20,
                                color: colors.textSecondary,
                              ),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            key: const ValueKey('appSearchMicButton'),
                            onLongPressStart: (_) =>
                                setState(() => _listeningToVoice = true),
                            onLongPressEnd: (_) =>
                                setState(() => _listeningToVoice = false),
                            child: AppIcon(
                              id: AppIconId.mic,
                              semanticLabel: 'Search by voice',
                              size: 20,
                              color: _listeningToVoice
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            key: const ValueKey('appSearchQrButton'),
                            onTap: widget.onQrTap,
                            child: AppIcon(
                              id: AppIconId.qrCode,
                              semanticLabel: 'Search by QR code',
                              size: 20,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_listeningToVoice) _VoiceWaveform(colors: colors),
            Expanded(
              child: ListView(
                key: const ValueKey('appSearchRecentList'),
                children: [
                  for (final recent in widget.recentSearches)
                    ListTile(
                      leading: AppIcon(
                        id: AppIconId.search,
                        semanticLabel: recent,
                        color: colors.textTertiary,
                        size: 20,
                      ),
                      title: Text(
                        recent,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      onTap: () {
                        if (widget.onRecentTap != null) {
                          widget.onRecentTap!(recent);
                          Navigator.of(context).pop();
                        } else {
                          _submit(recent);
                        }
                      },
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

/// A small pulsing bar waveform shown while the mic is press-held — DS
/// §3.6: "press-hold mic = waveform inline". No real audio is captured;
/// this is a visual affordance only (see this story's open questions).
class _VoiceWaveform extends StatefulWidget {
  final AppColors colors;
  const _VoiceWaveform({required this.colors});

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('appSearchVoiceWaveform'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 4,
                    height: 8 + (16 * ((_controller.value + (i * 0.2)) % 1.0)),
                    decoration: BoxDecoration(
                      color: widget.colors.primary,
                      borderRadius: AppRadius.xsRadius,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
