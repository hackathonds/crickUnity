import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

const double _slideCancelThreshold = 80;

/// DS §62: "voice-note hold-to-record with slide-cancel affordance."
/// PRD: "voice notes (hold-to-record, slide-cancel, 2x playback)." No
/// real audio-recording backend exists -- duration is a wall-clock
/// count while held, and the waveform is a static decorative row, not
/// an actual amplitude capture, flagged.
class VoiceNoteRecordButton extends StatefulWidget {
  final ValueChanged<int> onRecorded;

  const VoiceNoteRecordButton({super.key, required this.onRecorded});

  @override
  State<VoiceNoteRecordButton> createState() => VoiceNoteRecordButtonState();
}

class VoiceNoteRecordButtonState extends State<VoiceNoteRecordButton> {
  bool _recording = false;
  double _dragDx = 0;
  DateTime? _startedAt;

  void _startRecording() {
    setState(() {
      _recording = true;
      _dragDx = 0;
      _startedAt = DateTime.now();
    });
  }

  void _updateDrag(double dx) {
    setState(() => _dragDx = dx);
  }

  void _endRecording() {
    if (!_recording) return;
    final cancelled = _dragDx.abs() > _slideCancelThreshold;
    final duration = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds.clamp(1, 999);
    setState(() {
      _recording = false;
      _dragDx = 0;
      _startedAt = null;
    });
    if (!cancelled) widget.onRecorded(duration);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (!_recording) {
      return GestureDetector(
        key: const ValueKey('voiceNoteHoldTarget'),
        onLongPressStart: (_) => _startRecording(),
        onLongPressMoveUpdate: (details) =>
            _updateDrag(details.offsetFromOrigin.dx),
        onLongPressEnd: (_) => _endRecording(),
        onLongPressCancel: _endRecording,
        child: Icon(Icons.mic_none, color: colors.textSecondary),
      );
    }

    final cancelling = _dragDx.abs() > _slideCancelThreshold / 2;
    return GestureDetector(
      onLongPressMoveUpdate: (details) =>
          _updateDrag(details.offsetFromOrigin.dx),
      onLongPressEnd: (_) => _endRecording(),
      onLongPressCancel: _endRecording,
      child: Container(
        key: const ValueKey('voiceNoteRecordingIndicator'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: cancelling
              ? colors.error.withValues(alpha: 0.15)
              : colors.live.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fiber_manual_record,
              size: 14,
              color: cancelling ? colors.error : colors.live,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              cancelling ? 'Release to cancel' : '< Slide to cancel',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sent voice note's playback row -- no real audio backend, so
/// "playback" is a simulated progress animation over the tracked
/// duration, at the toggled speed.
class VoiceNoteBubble extends StatefulWidget {
  final int durationSeconds;

  const VoiceNoteBubble({super.key, required this.durationSeconds});

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _doubleSpeed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.duration = Duration(
        milliseconds: (widget.durationSeconds * 1000 / (_doubleSpeed ? 2 : 1))
            .round(),
      );
      _controller.forward(from: _controller.value == 1 ? 0 : _controller.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('voiceNotePlayButton'),
          icon: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                Icon(_controller.isAnimating ? Icons.pause : Icons.play_arrow),
          ),
          onPressed: _togglePlay,
        ),
        SizedBox(
          width: 80,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _controller.value,
                minHeight: 4,
                color: colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('${widget.durationSeconds}s'),
        TextButton(
          key: const ValueKey('voiceNoteSpeedToggle'),
          onPressed: () => setState(() => _doubleSpeed = !_doubleSpeed),
          child: Text(_doubleSpeed ? '2x' : '1x'),
        ),
      ],
    );
  }
}
