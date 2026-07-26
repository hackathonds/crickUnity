import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_document_models.dart';
import 'team_documents_provider.dart';
import 'team_member_models.dart';

/// DS §7 screen 20 (Documents), a "list + submit sheet" pattern screen
/// (DS §7 doesn't give Documents its own anatomy string beyond that
/// framing -- see team_document_models.dart's doc comment for the full
/// gap note). The Upload action is structurally absent for viewers
/// outside [documentUploadRoles], not merely disabled, matching the
/// pattern used for Announcements' composer FAB (E3-05).
class TeamDocumentsScreen extends ConsumerWidget {
  final String viewerName;
  final TeamMemberRole viewerRole;

  const TeamDocumentsScreen({
    super.key,
    required this.viewerName,
    required this.viewerRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(teamDocumentsProvider);
    final canUpload = documentUploadRoles.contains(viewerRole);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: canUpload
          ? FloatingActionButton(
              key: const ValueKey('uploadDocumentFab'),
              onPressed: () => _showUploadSheet(context),
              child: const Icon(Icons.upload_file),
            )
          : null,
      body: state.documents.isEmpty
          ? Center(
              child: Text(
                'No documents yet.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final doc = state.documents[index];
                return Container(
                  key: ValueKey('document_${doc.id}'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Uploaded by ${doc.uploaderName} · '
                              '${doc.uploadedAt.day}/${doc.uploadedAt.month}/'
                              '${doc.uploadedAt.year}',
                              style: AppTypography.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Upload document',
      contentBuilder: (context) => _UploadSheetContent(
        uploaderName: viewerName,
        uploaderRole: viewerRole,
      ),
    );
  }
}

class _UploadSheetContent extends ConsumerStatefulWidget {
  final String uploaderName;
  final TeamMemberRole uploaderRole;

  const _UploadSheetContent({
    required this.uploaderName,
    required this.uploaderRole,
  });

  @override
  ConsumerState<_UploadSheetContent> createState() =>
      _UploadSheetContentState();
}

class _UploadSheetContentState extends ConsumerState<_UploadSheetContent> {
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "A real file picker isn't available yet -- no file-storage "
            'package exists in this codebase. Name the document to '
            'stand in for choosing a file.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('documentNameField'),
            label: 'Document name',
            controller: _nameController,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              key: const ValueKey('documentUploadError'),
              style: AppTypography.caption.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('documentUploadButton'),
            variant: AppButtonVariant.primary,
            label: 'Upload',
            fullWidth: true,
            onPressed: () {
              final result = ref
                  .read(teamDocumentsProvider.notifier)
                  .upload(
                    name: _nameController.text,
                    uploaderName: widget.uploaderName,
                    uploaderRole: widget.uploaderRole,
                  );
              if (result.succeeded) {
                Navigator.of(context).pop();
              } else {
                setState(() => _error = result.error);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
