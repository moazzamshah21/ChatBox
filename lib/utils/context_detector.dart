/// Detects user context/sentiment from message text to adjust AI tone.
/// Used to build a dynamic system prompt (softer for tired/sad, technical for coding, playful for jokes).
enum ResponseTone {
  normal,
  soft,      // user seems tired/sad → soften tone
  technical, // user is coding → shorter, technical replies
  playful,   // user is joking → playful response
}

/// Simple keyword + pattern detection (no external NLP).
ResponseTone detectTone(String text) {
  if (text.isEmpty) return ResponseTone.normal;
  final lower = text.trim().toLowerCase();

  // Negative / tired / sad sentiment
  const softKeywords = [
    'tired', 'exhausted', 'sad', 'down', 'stressed', 'overwhelmed',
    'anxious', 'worried', 'bad day', 'rough day', 'feeling low',
    'depressed', 'lonely', 'miss', 'sorry', 'upset', 'frustrated',
  ];
  final softEmoji = RegExp(r'[😞😢😔🥺😭😩😫💔]');
  if (softEmoji.hasMatch(text) || softKeywords.any((k) => lower.contains(k))) {
    return ResponseTone.soft;
  }

  // Jokes / playful
  const jokeKeywords = [
    'lol', 'lmao', 'haha', 'hahaha', '😂', 'that\'s funny', 'funny',
    'joke', 'kidding', 'just kidding', 'jk', 'rofl', '😂', '🤣',
  ];
  if (jokeKeywords.any((k) => lower.contains(k)) || RegExp(r'[😂🤣😄]').hasMatch(text)) {
    return ResponseTone.playful;
  }

  // Coding context: technical terms, code-like patterns
  const codeKeywords = [
    'function', 'class', 'def ', 'const ', 'let ', 'var ', 'import ',
    'return', 'void', 'async', 'await', 'bug', 'error', 'exception',
    'widget', 'build', 'flutter', 'dart', 'api', 'json', 'null',
    'syntax', 'compile', 'debug', 'refactor', 'merge', 'commit',
  ];
  final hasBacktickCode = text.contains('`');
  final hasCodeKeywords = codeKeywords.any((k) => lower.contains(k));
  if (hasBacktickCode || hasCodeKeywords) {
    return ResponseTone.technical;
  }

  return ResponseTone.normal;
}

/// Returns a short system-prompt snippet to prepend for the detected tone.
String toneSystemPrompt(ResponseTone tone) {
  switch (tone) {
    case ResponseTone.soft:
      return 'The user seems tired or down. Use a warm, gentle, supportive tone. Keep it concise and kind.';
    case ResponseTone.technical:
      return 'The user is likely coding or asking something technical. Be concise, direct, and technical. Prefer short answers and code when relevant.';
    case ResponseTone.playful:
      return 'The user is in a lighthearted mood. Respond in a friendly, playful way when appropriate—a bit of wit is welcome.';
    case ResponseTone.normal:
      return '';
  }
}
