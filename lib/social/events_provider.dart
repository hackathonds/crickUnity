import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rewards/rewards_provider.dart';
import 'composer_screen.dart';
import 'event_models.dart';

enum RsvpFailureReason { eventFull, insufficientCoins }

class EventsState {
  final List<CricketEvent> events;

  const EventsState({this.events = const []});

  CricketEvent? eventById(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  EventsState copyWith({List<CricketEvent>? events}) =>
      EventsState(events: events ?? this.events);
}

/// PRD §12.5 -- E7-06's Events engine.
class EventsNotifier extends Notifier<EventsState> {
  @override
  EventsState build() => EventsState(events: _seedEvents());

  static List<CricketEvent> _seedEvents() {
    final now = DateTime.now();
    return [
      CricketEvent(
        id: 'event-trials',
        title: 'Strikers CC Open Trials',
        template: EventTemplate.trials,
        dateTime: now.add(const Duration(days: 5)),
        coHostNames: const ['Arjun Rao'],
        capacity: 30,
      ),
      CricketEvent(
        id: 'event-screening',
        title: 'World Cup Final Screening Night',
        template: EventTemplate.screeningNight,
        dateTime: now.add(const Duration(days: 2)),
        ticketPriceCoins: 50,
        capacity: 20,
      ),
    ];
  }

  void createEvent(CricketEvent event) {
    state = state.copyWith(events: [...state.events, event]);
  }

  /// PRD's "ticketing" -- a `going` RSVP on a ticketed event genuinely
  /// spends coins via rewardsProvider's FIFO ledger (E6-05), same
  /// engine every other coin spend in the app goes through.
  RsvpFailureReason? rsvp(String eventId, RsvpStatus status) {
    final event = state.eventById(eventId);
    if (event == null) return null;
    final wasGoing = event.rsvpByName[composerViewerName] == RsvpStatus.going;

    if (status == RsvpStatus.going && !wasGoing) {
      if (event.isFull) return RsvpFailureReason.eventFull;
      if (event.ticketPriceCoins != null) {
        final spent = ref
            .read(rewardsProvider.notifier)
            .spendCoins(
              event.ticketPriceCoins!,
              label: 'Ticket: ${event.title}',
            );
        if (!spent) return RsvpFailureReason.insufficientCoins;
      }
    }

    _update(
      eventId,
      (e) =>
          e.copyWith(rsvpByName: {...e.rsvpByName, composerViewerName: status}),
    );
    return null;
  }

  void addDiscussionMessage(String eventId, String message) {
    _update(
      eventId,
      (e) => e.copyWith(
        discussionMessages: [
          ...e.discussionMessages,
          '$composerViewerName: $message',
        ],
      ),
    );
  }

  void _update(String eventId, CricketEvent Function(CricketEvent) transform) {
    state = state.copyWith(
      events: [
        for (final e in state.events)
          if (e.id == eventId) transform(e) else e,
      ],
    );
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, EventsState>(
  EventsNotifier.new,
);
