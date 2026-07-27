import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'premium_provider.dart';

/// DS §11.14: "Family = manage-members screen (4 slots, invite by
/// QR/link, guardian bundles); manage/cancel states plain." No real
/// QR/deep-link generation exists -- invite is a Clipboard-copy mock
/// link plus a name field to simulate acceptance, same convention as
/// every other missing-integration gap this session.
class FamilyManagerScreen extends ConsumerWidget {
  const FamilyManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final premium = ref.watch(premiumProvider);
    final notifier = ref.read(premiumProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Family members')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (var i = 0; i < familySlotCount; i++)
            _FamilySlotCard(
              key: ValueKey('familySlot_$i'),
              slotIndex: i,
              name: premium.familySlots[i],
              guardianBundle: premium.guardianBundleBySlot[i],
              colors: colors,
              onInvite: (name) => notifier.inviteFamilyMember(i, name),
              onRemove: () => notifier.removeFamilyMember(i),
              onGuardianBundleChanged: (value) =>
                  notifier.setGuardianBundle(i, value),
            ),
        ],
      ),
    );
  }
}

class _FamilySlotCard extends StatefulWidget {
  final int slotIndex;
  final String? name;
  final bool guardianBundle;
  final AppColors colors;
  final ValueChanged<String> onInvite;
  final VoidCallback onRemove;
  final ValueChanged<bool> onGuardianBundleChanged;

  const _FamilySlotCard({
    super.key,
    required this.slotIndex,
    required this.name,
    required this.guardianBundle,
    required this.colors,
    required this.onInvite,
    required this.onRemove,
    required this.onGuardianBundleChanged,
  });

  @override
  State<_FamilySlotCard> createState() => _FamilySlotCardState();
}

class _FamilySlotCardState extends State<_FamilySlotCard> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: widget.name == null
          ? Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Slot ${widget.slotIndex + 1} -- invite by name',
                    controller: _nameController,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  key: ValueKey('inviteFamilySlotButton_${widget.slotIndex}'),
                  variant: AppButtonVariant.secondary,
                  label: 'Invite',
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: 'https://cricunity.app/family-invite/mock',
                      ),
                    );
                    if (_nameController.text.trim().isNotEmpty) {
                      widget.onInvite(_nameController.text.trim());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied')),
                    );
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name!,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    AppButton(
                      key: ValueKey(
                        'removeFamilySlotButton_${widget.slotIndex}',
                      ),
                      variant: AppButtonVariant.tertiary,
                      label: 'Remove',
                      onPressed: widget.onRemove,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Guardian bundle',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      key: ValueKey('guardianBundleSwitch_${widget.slotIndex}'),
                      value: widget.guardianBundle,
                      onChanged: widget.onGuardianBundleChanged,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
