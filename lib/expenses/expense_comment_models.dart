/// Backlog addendum (E5-11): "Participant-only threads w/ @mentions,
/// dispute-link from comment."
class ExpenseComment {
  final String id;
  final String expenseId;
  final String authorName;
  final String text;
  final List<String> mentionedNames;
  final DateTime createdAt;

  const ExpenseComment({
    required this.id,
    required this.expenseId,
    required this.authorName,
    required this.text,
    required this.mentionedNames,
    required this.createdAt,
  });
}

/// Extracts "@Name" mentions from [text] against the known
/// [candidateNames] pool (participant names can contain spaces, e.g.
/// "Kabir Singh," so this matches the longest candidate name found
/// immediately after each '@' rather than splitting on whitespace).
List<String> parseMentions(String text, List<String> candidateNames) {
  final sorted = [...candidateNames]
    ..sort((a, b) => b.length.compareTo(a.length));
  final mentioned = <String>{};
  for (final match in RegExp('@').allMatches(text)) {
    final rest = text.substring(match.end);
    for (final name in sorted) {
      if (rest.startsWith(name)) {
        mentioned.add(name);
        break;
      }
    }
  }
  return mentioned.toList();
}
