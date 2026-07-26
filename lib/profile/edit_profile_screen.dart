import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_dialog.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'edit_profile_provider.dart';
import 'title_picker_sheet.dart';
import 'titles_models.dart';

const List<String> _availableLanguages = [
  'English',
  'Hindi',
  'Marathi',
  'Tamil',
  'Punjabi',
];

/// DS §7 screen 6: "Grouped form sections; sticky Save appears only on
/// dirty state; name-change shows '2/yr' helper; leaving dirty ->
/// Save/Discard dialog." PRD §5.1's field list, minus roles chips (PRD §2:
/// roles are activity-inferred, never self-declared) and photo/cover
/// (no image-picker package exists -- see E1-03's Photo step for the same
/// gap, flagged there already).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    // These controllers are the only writer/reader pair for their fields
    // while this screen is open, so a one-time seed from the provider's
    // starting state (rather than resyncing on every rebuild, which would
    // fight the user's cursor position) is safe.
    final state = ref.read(editProfileProvider);
    _nameController = TextEditingController(text: state.name);
    _nicknameController = TextEditingController(text: state.nickname);
    _cityController = TextEditingController(text: state.city);
    _bioController = TextEditingController(text: state.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleBackAttempt() async {
    // Short labels deliberately: AppDialogShell's action Row (E0-05) has
    // no Flexible/wrap fallback, so a longer pair like "Keep editing" /
    // "Discard" overflows its 320-wide shell -- a latent bug in a shared
    // component, flagged in this story's PR rather than fixed here
    // (out of scope for an Edit Profile story).
    final discard = await showAppConfirmDialog(
      context: context,
      title: 'Discard changes?',
      body: "You have unsaved changes. If you leave now, they'll be lost.",
      cancelLabel: 'Cancel',
      confirmLabel: 'Discard',
    );
    if (discard == true) {
      ref.read(editProfileProvider.notifier).discard();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(editProfileProvider);
    final notifier = ref.read(editProfileProvider.notifier);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.lg),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAttempt();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionLabel('Basic information'),
                      AppTextField(
                        key: const ValueKey('editProfileNameField'),
                        label: 'Name',
                        controller: _nameController,
                        helperText: state.nameChangeBlocked
                            ? null
                            : '${state.nameChangesRemaining} of '
                                  '$maxNameChangesPerYear name changes '
                                  'remaining this year',
                        validator: (_) => state.nameChangeBlocked
                            ? "You've used all $maxNameChangesPerYear name "
                                  'changes for this year'
                            : null,
                        onChanged: notifier.setName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        key: const ValueKey('editProfileNicknameField'),
                        label: 'Display nickname (optional)',
                        controller: _nicknameController,
                        onChanged: notifier.setNickname,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        key: const ValueKey('editProfileCityField'),
                        label: 'City',
                        controller: _cityController,
                        onChanged: notifier.setCity,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        key: const ValueKey('editProfileAgeBandSwitch'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show age band on my profile'),
                        subtitle: const Text(
                          'Your exact date of birth always stays private.',
                        ),
                        value: state.showAgeBand,
                        onChanged: notifier.setShowAgeBand,
                      ),
                      sectionLabel('Titles'),
                      GestureDetector(
                        key: const ValueKey('editProfileTitlesRow'),
                        onTap: () => showTitlePickerSheet(
                          context: context,
                          name: state.name,
                          titles: mockEarnedTitles(),
                          currentEquipped: state.equippedTitle,
                          onEquip: notifier.equipTitle,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.equippedTitle ?? 'None equipped',
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                      sectionLabel('Languages'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final language in _availableLanguages)
                            AppChipActionButton(
                              key: ValueKey('editProfileLanguage_$language'),
                              label: language,
                              selected: state.languages.contains(language),
                              onPressed: () =>
                                  notifier.toggleLanguage(language),
                            ),
                        ],
                      ),
                      sectionLabel('Bio'),
                      AppTextField(
                        key: const ValueKey('editProfileBioField'),
                        label: 'Bio',
                        controller: _bioController,
                        helperText: '${state.bio.length}/150',
                        validator: (value) => value.length > 150
                            ? 'Keep it to 150 characters'
                            : null,
                        onChanged: notifier.setBio,
                      ),
                    ],
                  ),
                ),
              ),
              if (state.isDirty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    key: const ValueKey('editProfileSaveButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Save',
                    fullWidth: true,
                    onPressed: state.canSave
                        ? () {
                            notifier.save();
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
