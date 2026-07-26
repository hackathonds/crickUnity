/// DS §7 screen 13: "cells 44 tri-state glyphs." PRD §6.11 describes a
/// 4th "⏳(no response)" state, reconciled here as the *absence* of a
/// response (a null cell) rather than a 4th glyph -- the glyphs
/// themselves are tri-state (yes/maybe/no), matching DS's literal
/// wording, while "no response yet" is simply an empty cell.
enum AvailabilityResponse { yes, maybe, no }

const Map<AvailabilityResponse, String> availabilityResponseGlyphs = {
  AvailabilityResponse.yes: '✔',
  AvailabilityResponse.maybe: '❓',
  AvailabilityResponse.no: '✖',
};

const Map<AvailabilityResponse, String> availabilityResponseLabels = {
  AvailabilityResponse.yes: 'Available',
  AvailabilityResponse.maybe: 'Maybe',
  AvailabilityResponse.no: 'Not available',
};

class AvailabilityEvent {
  final String id;
  final String label;

  const AvailabilityEvent({required this.id, required this.label});
}

/// Mock roster x events grid for the debug demo and tests -- no backend
/// availability-matrix service exists yet.
List<String> mockMatrixMembers() => const [
  'Priya Nair',
  'Kabir Singh',
  'Ananya Iyer',
  'Farhan Ali',
];

List<AvailabilityEvent> mockMatrixEvents() => const [
  AvailabilityEvent(id: 'evt-1', label: 'vs Titans, Sun'),
  AvailabilityEvent(id: 'evt-2', label: 'Practice, Wed'),
];

/// Keyed "member|eventId" -> response. Absent key = no response yet.
Map<String, AvailabilityResponse> mockMatrixResponses() => const {
  'Priya Nair|evt-1': AvailabilityResponse.yes,
  'Kabir Singh|evt-1': AvailabilityResponse.yes,
  'Ananya Iyer|evt-1': AvailabilityResponse.maybe,
  // Farhan Ali|evt-1 intentionally absent -- no response yet.
  'Priya Nair|evt-2': AvailabilityResponse.no,
  'Kabir Singh|evt-2': AvailabilityResponse.yes,
  'Ananya Iyer|evt-2': AvailabilityResponse.yes,
  'Farhan Ali|evt-2': AvailabilityResponse.no,
};
