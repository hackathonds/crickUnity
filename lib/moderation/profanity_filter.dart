/// PRD §12.10: "Profanity auto-filter with user-level 'hide offensive
/// comments' default ON." A small mock word list stands in for a real
/// profanity-detection service, same flagged-mock convention as every
/// other missing-backend gap this session -- but the masking itself is
/// genuinely applied wherever this is called, not a no-op toggle.
const List<String> _mockProfaneWords = ['damn', 'hell', 'crap', 'idiot'];

String maskProfanity(String text, {required bool enabled}) {
  if (!enabled) return text;
  var result = text;
  for (final word in _mockProfaneWords) {
    final pattern = RegExp('\\b$word\\b', caseSensitive: false);
    result = result.replaceAll(pattern, '*' * word.length);
  }
  return result;
}
