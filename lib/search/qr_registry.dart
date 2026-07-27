import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clubs/club_provider.dart';
import '../grounds/booking_models.dart';
import '../grounds/bookings_provider.dart';
import '../grounds/grounds_provider.dart';
import '../social/groups_provider.dart';
import '../tournaments/tournament_models.dart';
import '../tournaments/tournaments_provider.dart';
import 'qr_models.dart';

/// Aggregates every real "QR-bearing" object across the modules built
/// this session into one lookup list -- see qr_models.dart's top-of-
/// file note for what's genuine here vs. flagged. Booking QR codes
/// reuse the actual Booking.qrCode string generated at hold time
/// (E9-03); every other type mints a stable derived code from the
/// object's real id, since those modules don't carry their own QR
/// string field.
List<QrCodeEntry> availableQrCodes(WidgetRef ref) {
  final entries = <QrCodeEntry>[];

  for (final ground in ref.watch(groundsProvider).grounds) {
    entries.add(
      QrCodeEntry(
        code: 'QR-GROUND-${ground.id}',
        type: QrObjectType.ground,
        label: ground.name,
        targetId: ground.id,
      ),
    );
  }

  for (final tournament in ref.watch(tournamentsProvider).tournaments) {
    if (tournament.status != TournamentStatus.published) continue;
    entries.add(
      QrCodeEntry(
        code: 'QR-TOURNAMENT-${tournament.id}',
        type: QrObjectType.tournament,
        label: tournament.name,
        targetId: tournament.id,
      ),
    );
  }

  final club = ref.watch(clubProvider).club;
  entries.add(
    QrCodeEntry(
      code: 'QR-CLUB-${club.id}',
      type: QrObjectType.club,
      label: club.name,
      targetId: club.id,
    ),
  );

  for (final group in ref.watch(groupsProvider).groups) {
    entries.add(
      QrCodeEntry(
        code: 'QR-GROUP-${group.id}',
        type: QrObjectType.group,
        label: group.name,
        targetId: group.id,
      ),
    );
  }

  for (final booking in ref.watch(bookingsProvider).bookings) {
    if (!booking.isActive) continue;
    entries.add(
      QrCodeEntry(
        code: booking.qrCode,
        type: QrObjectType.booking,
        label:
            '${booking.groundName} · ${bookingPurposeLabels[booking.purpose]}',
        targetId: booking.id,
      ),
    );
  }

  return entries;
}
