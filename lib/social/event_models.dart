/// PRD §12.5: "Events: cricket-y templates (screening night, trials,
/// tournament ceremony) with RSVP, co-hosts, discussion tab, reminder
/// cadence." Backlog adds "ticketing" -- modeled as an optional
/// coin-priced ticket, genuinely spent via rewards_provider.dart's
/// FIFO ledger (events_provider.dart), not a mocked deduction.
enum EventTemplate { screeningNight, trials, tournamentCeremony, custom }

const Map<EventTemplate, String> eventTemplateLabels = {
  EventTemplate.screeningNight: 'Screening Night',
  EventTemplate.trials: 'Trials',
  EventTemplate.tournamentCeremony: 'Tournament Ceremony',
  EventTemplate.custom: 'Custom',
};

enum RsvpStatus { none, going, maybe, notGoing }

const Map<RsvpStatus, String> rsvpStatusLabels = {
  RsvpStatus.none: 'Not responded',
  RsvpStatus.going: 'Going',
  RsvpStatus.maybe: 'Maybe',
  RsvpStatus.notGoing: "Can't go",
};

/// PRD names no exact cadence set -- a fixed 3-step list (1 week / 1
/// day / 1 hour before) is a flagged judgment call.
const List<String> eventReminderCadence = [
  '1 week before',
  '1 day before',
  '1 hour before',
];

class CricketEvent {
  final String id;
  final String title;
  final EventTemplate template;
  final DateTime dateTime;
  final List<String> coHostNames;
  final Map<String, RsvpStatus> rsvpByName;
  final List<String> discussionMessages;
  final int? ticketPriceCoins;
  final int? capacity;

  const CricketEvent({
    required this.id,
    required this.title,
    required this.template,
    required this.dateTime,
    this.coHostNames = const [],
    this.rsvpByName = const {},
    this.discussionMessages = const [],
    this.ticketPriceCoins,
    this.capacity,
  });

  int get goingCount =>
      rsvpByName.values.where((s) => s == RsvpStatus.going).length;

  bool get isFull => capacity != null && goingCount >= capacity!;

  CricketEvent copyWith({
    Map<String, RsvpStatus>? rsvpByName,
    List<String>? discussionMessages,
  }) {
    return CricketEvent(
      id: id,
      title: title,
      template: template,
      dateTime: dateTime,
      coHostNames: coHostNames,
      rsvpByName: rsvpByName ?? this.rsvpByName,
      discussionMessages: discussionMessages ?? this.discussionMessages,
      ticketPriceCoins: ticketPriceCoins,
      capacity: capacity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'template': template.name,
    'dateTime': dateTime.toIso8601String(),
    'coHostNames': coHostNames,
    'rsvpByName': {
      for (final entry in rsvpByName.entries) entry.key: entry.value.name,
    },
    'discussionMessages': discussionMessages,
    'ticketPriceCoins': ticketPriceCoins,
    'capacity': capacity,
  };

  factory CricketEvent.fromJson(Map<String, dynamic> json) {
    return CricketEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      template: EventTemplate.values.byName(json['template'] as String),
      dateTime: DateTime.parse(json['dateTime'] as String),
      coHostNames: [for (final n in json['coHostNames'] as List) n as String],
      rsvpByName: {
        for (final entry
            in (json['rsvpByName'] as Map<String, dynamic>).entries)
          entry.key: RsvpStatus.values.byName(entry.value as String),
      },
      discussionMessages: [
        for (final m in json['discussionMessages'] as List) m as String,
      ],
      ticketPriceCoins: json['ticketPriceCoins'] as int?,
      capacity: json['capacity'] as int?,
    );
  }
}
