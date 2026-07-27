import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// PRD §12.6: "Mentions @user (notifies; mentionability per privacy) ...
/// Hashtags -> tag pages with Top/Recent." No real profile-routing or
/// notification pipeline exists for mentions -- tapping one is a mock
/// snackbar, flagged, same convention as every other missing-
/// integration gap this session. Hashtags get real navigation
/// (hashtag_screen.dart) since that page is this story's own scope.
final RegExp _tokenPattern = RegExp(r'([@#][A-Za-z0-9_]+)');

/// Splits [text] into plain spans plus tappable @mention/#hashtag spans.
List<InlineSpan> buildRichTextSpans({
  required String text,
  required TextStyle baseStyle,
  required TextStyle tokenStyle,
  required ValueChanged<String> onMentionTap,
  required ValueChanged<String> onHashtagTap,
}) {
  final spans = <InlineSpan>[];
  var lastEnd = 0;
  for (final match in _tokenPattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }
    final token = match.group(0)!;
    spans.add(
      TextSpan(
        text: token,
        style: tokenStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (token.startsWith('@')) {
              onMentionTap(token.substring(1));
            } else {
              onHashtagTap(token.substring(1));
            }
          },
      ),
    );
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }
  return spans;
}
