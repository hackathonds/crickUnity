import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'composer_screen.dart';
import 'event_models.dart';
import 'events_provider.dart';

const Map<RsvpFailureReason, String> _rsvpFailureMessages = {
  RsvpFailureReason.eventFull: 'This event is full.',
  RsvpFailureReason.insufficientCoins: 'Not enough coins for a ticket.',
};

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _discussionController = TextEditingController();

  @override
  void dispose() {
    _discussionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final events = ref.watch(eventsProvider).events;
    final event = events.firstWhere((e) => e.id == widget.eventId);
    final notifier = ref.read(eventsProvider.notifier);
    final myRsvp = event.rsvpByName[composerViewerName] ?? RsvpStatus.none;

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year}',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          if (event.coHostNames.isNotEmpty)
            Text(
              'Co-hosts: ${event.coHostNames.join(', ')}',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          if (event.ticketPriceCoins != null)
            Text(
              'Ticket: ${event.ticketPriceCoins} coins',
              style: AppTypography.caption.copyWith(color: colors.coin),
            ),
          Text(
            '${event.goingCount}${event.capacity != null ? "/${event.capacity}" : ""} going',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSegmentedControl<RsvpStatus>(
            key: const ValueKey('rsvpSelector'),
            options: const [
              RsvpStatus.going,
              RsvpStatus.maybe,
              RsvpStatus.notGoing,
            ],
            value: myRsvp == RsvpStatus.none ? RsvpStatus.maybe : myRsvp,
            onChanged: (status) {
              final reason = notifier.rsvp(event.id, status);
              if (reason != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_rsvpFailureMessages[reason]!)),
                );
              }
            },
            labelBuilder: (status) => rsvpStatusLabels[status]!,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Reminders',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          for (final r in eventReminderCadence)
            Text(
              '• $r',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Discussion',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final message in event.discussionMessages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Text(message),
            ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Add a comment',
                  controller: _discussionController,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                key: const ValueKey('addDiscussionMessageButton'),
                variant: AppButtonVariant.secondary,
                label: 'Send',
                onPressed: () {
                  if (_discussionController.text.trim().isEmpty) return;
                  notifier.addDiscussionMessage(
                    event.id,
                    _discussionController.text.trim(),
                  );
                  _discussionController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
