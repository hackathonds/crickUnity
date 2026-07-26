import 'package:cricunity/teams/team_documents_provider.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC: a privileged role can upload a document', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(teamDocumentsProvider.notifier);

    final result = notifier.upload(
      name: 'Player consent forms.pdf',
      uploaderName: 'Rohan Kapoor',
      uploaderRole: TeamMemberRole.captain,
    );

    expect(result.succeeded, isTrue);
    expect(
      container
          .read(teamDocumentsProvider)
          .documents
          .any((d) => d.name == 'Player consent forms.pdf'),
      isTrue,
    );
  });

  test('AC: a plain player cannot upload a document', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(teamDocumentsProvider.notifier);
    final before = container.read(teamDocumentsProvider).documents.length;

    final result = notifier.upload(
      name: 'Sneaky upload.pdf',
      uploaderName: 'Sana Iyer',
      uploaderRole: TeamMemberRole.player,
    );

    expect(result.succeeded, isFalse);
    expect(container.read(teamDocumentsProvider).documents.length, before);
  });

  test('an empty document name is rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(teamDocumentsProvider.notifier);

    final result = notifier.upload(
      name: '   ',
      uploaderName: 'Rohan Kapoor',
      uploaderRole: TeamMemberRole.owner,
    );

    expect(result.succeeded, isFalse);
  });
}
