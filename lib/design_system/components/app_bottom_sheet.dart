import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_dialog.dart';

/// DS §3.5 detents.
const double sheetPeekDetent = 0.30;
const double sheetHalfDetent = 0.60;
const double sheetFullDetent = 0.92;

/// Opens the standard bottom sheet shell — detents 30/60/92, grabber, an
/// optional 56h title row with a 44-target Close, and (DS §3.5) drag
/// physics where dragging below peek dismisses *unless* [hasUnsavedInput]
/// is true, in which case it bounces back to peek and offers a Save/Discard
/// dialog instead (this story's one literal AC).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder contentBuilder,
  String? title,
  bool hasUnsavedInput = false,
  VoidCallback? onSave,
  VoidCallback? onDiscard,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: false, // custom drag handling below, see _AppBottomSheetState
    backgroundColor: Colors.transparent,
    builder: (context) => AppBottomSheet(
      title: title,
      hasUnsavedInput: hasUnsavedInput,
      onSave: onSave,
      onDiscard: onDiscard,
      contentBuilder: contentBuilder,
    ),
  );
}

class AppBottomSheet extends StatefulWidget {
  final String? title;
  final bool hasUnsavedInput;
  final WidgetBuilder contentBuilder;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;

  const AppBottomSheet({
    super.key,
    required this.contentBuilder,
    this.title,
    this.hasUnsavedInput = false,
    this.onSave,
    this.onDiscard,
  });

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}

class _AppBottomSheetState extends State<AppBottomSheet>
    with SingleTickerProviderStateMixin {
  final _sheetController = DraggableScrollableController();
  late final AnimationController _bounceController;
  bool _dismissing = false;
  double _grabberDragExtent = 0;

  /// Downward drag distance on the grabber past which a release counts as
  /// a dismiss attempt — DS §3.5: "below-peek drag = dismiss". The grabber
  /// is the dedicated drag-to-dismiss handle; dragging the body resizes
  /// between detents instead (`DraggableScrollableSheet`'s own behavior),
  /// keeping the two gestures unambiguous.
  static const double _dismissDragThreshold = 60;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onGrabberDragUpdate(DragUpdateDetails details) {
    _grabberDragExtent = (_grabberDragExtent + details.delta.dy).clamp(
      0,
      double.infinity,
    );
  }

  void _onGrabberDragEnd(DragEndDetails details) {
    final extent = _grabberDragExtent;
    _grabberDragExtent = 0;
    if (extent > _dismissDragThreshold) {
      _attemptDismiss();
    }
  }

  Future<void> _attemptDismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    try {
      if (!widget.hasUnsavedInput) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      await _bounce();
      if (!mounted) return;

      final action = await showAppDialog<_UnsavedAction>(
        context: context,
        builder: (context) => _UnsavedChangesDialog(),
      );

      if (action == _UnsavedAction.discard) {
        widget.onDiscard?.call();
        if (mounted) Navigator.of(context).pop();
      } else if (action == _UnsavedAction.save) {
        widget.onSave?.call();
        if (mounted) Navigator.of(context).pop();
      }
      // action == null (dismissed without choosing): sheet stays open.
    } finally {
      _dismissing = false;
    }
  }

  Future<void> _bounce() async {
    await _bounceController.forward();
    await _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return PopScope(
      canPop: !widget.hasUnsavedInput,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _attemptDismiss();
      },
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          final dy = Curves.easeOut.transform(_bounceController.value) * 10;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: sheetHalfDetent,
          minChildSize: sheetPeekDetent,
          maxChildSize: sheetFullDetent,
          snap: true,
          snapSizes: const [sheetPeekDetent, sheetHalfDetent, sheetFullDetent],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onGrabberDragUpdate,
                    onVerticalDragEnd: _onGrabberDragEnd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Center(
                        child: Container(
                          key: const ValueKey('appBottomSheetGrabber'),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: AppRadius.fullRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.title != null)
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Text(
                                widget.title!,
                                style: AppTypography.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            icon: const Icon(Icons.close),
                            color: colors.textPrimary,
                            onPressed: _attemptDismiss,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: widget.contentBuilder(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _UnsavedAction { save, discard }

class _UnsavedChangesDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppDialogShell(
      colors: colors,
      title: 'Save your changes?',
      body: "You have unsaved input — you'll lose it if you discard.",
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_UnsavedAction.discard),
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_UnsavedAction.save),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
