/// A segment of parsed message content: either plain text or a code block.
sealed class ContentSegment {}

class TextSegment extends ContentSegment {
  TextSegment(this.text);
  final String text;
}

class CodeSegment extends ContentSegment {
  CodeSegment(this.code, {this.language});
  final String code;
  final String? language;
}

/// Parses markdown-style content into text and code segments.
/// Supports ```language\ncode\n``` blocks.
List<ContentSegment> parseMessageContent(String content) {
  if (content.isEmpty) return [TextSegment('')];

  const fence = '```';
  final segments = <ContentSegment>[];
  var start = 0;

  while (true) {
    final codeStart = content.indexOf(fence, start);
    if (codeStart == -1) {
      final rest = content.substring(start).trim();
      if (rest.isNotEmpty) segments.add(TextSegment(rest));
      break;
    }

    final textBefore = content.substring(start, codeStart).trim();
    if (textBefore.isNotEmpty) segments.add(TextSegment(textBefore));

    final afterFence = content.indexOf('\n', codeStart + fence.length);
    final language = afterFence == -1
        ? null
        : content
            .substring(codeStart + fence.length, afterFence)
            .trim()
            .split(RegExp(r'\s'))
            .firstOrNull;
    final codeStartIndex = afterFence == -1 ? codeStart + fence.length : afterFence + 1;
    final codeEnd = content.indexOf(fence, codeStartIndex);
    final code = codeEnd == -1
        ? content.substring(codeStartIndex)
        : content.substring(codeStartIndex, codeEnd).trimRight();
    segments.add(CodeSegment(code, language: (language != null && language.isNotEmpty) ? language : null));

    start = codeEnd == -1 ? content.length : codeEnd + fence.length;
    if (codeEnd == -1) break;
  }

  return segments.isEmpty ? [TextSegment(content)] : segments;
}
