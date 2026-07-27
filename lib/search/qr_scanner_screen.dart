import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clubs/club_home_screen.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../grounds/booking_ticket_screen.dart';
import '../grounds/bookings_provider.dart';
import '../grounds/ground_profile_screen.dart';
import '../social/group_detail_screen.dart';
import 'qr_models.dart';
import 'qr_registry.dart';

/// PRD §16: "QR Search: camera icon -> scan any CricUnity QR (profile/
/// team/ground/match/tournament) -> jump straight to object; also
/// reads booking check-in QRs." See qr_models.dart's top-of-file note
/// for the flagged camera gap and the missing-Tournament-Home caveat.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _resolve(String code) {
    final entries = availableQrCodes(ref);
    final entry = entries.where((e) => e.code == code).firstOrNull;
    if (entry == null) {
      setState(() => _error = 'No CricUnity object matches this QR code.');
      return;
    }
    setState(() => _error = null);
    _jumpTo(entry);
  }

  void _jumpTo(QrCodeEntry entry) {
    switch (entry.type) {
      case QrObjectType.ground:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroundProfileScreen(groundId: entry.targetId),
          ),
        );
      case QrObjectType.club:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ClubHomeScreen()));
      case QrObjectType.group:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(groupId: entry.targetId),
          ),
        );
      case QrObjectType.tournament:
        // No single "Tournament Home" screen exists yet (flagged,
        // qr_models.dart top-of-file note) -- confirm the scan
        // genuinely resolved rather than mis-navigate.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanned tournament: ${entry.label} (no single Tournament Home screen exists yet).',
            ),
          ),
        );
      case QrObjectType.booking:
        // PRD: "also reads booking check-in QRs." Genuinely marks the
        // booking checked in (E9-06's real checkIn action) before
        // showing the ticket.
        ref.read(bookingsProvider.notifier).checkIn(entry.targetId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingTicketScreen(bookingId: entry.targetId),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final entries = availableQrCodes(ref);

    return Scaffold(
      appBar: AppBar(title: const Text('QR search')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'No camera/QR-decoding package exists yet -- tap a code below '
            '(standing in for a camera scan) or paste one manually.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('qrCodeManualField'),
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Paste QR code'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _error!,
                style: AppTypography.caption.copyWith(color: colors.error),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('resolveQrCodeButton'),
            variant: AppButtonVariant.primary,
            label: 'Jump to object',
            fullWidth: true,
            onPressed: () => _resolve(_codeController.text.trim()),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Available QR codes', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in entries)
            ListTile(
              key: ValueKey('qrCodeRow_${entry.code}'),
              contentPadding: EdgeInsets.zero,
              title: Text(entry.label),
              subtitle: Text('${entry.type.name} · ${entry.code}'),
              onTap: () => _jumpTo(entry),
            ),
        ],
      ),
    );
  }
}
