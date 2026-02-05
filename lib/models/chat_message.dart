enum MessageRole { user, assistant }

class ChatMessage {
  final String content;
  final MessageRole role;
  /// Local file path of attached image (user messages only). Used for display and for vision API.
  final String? imagePath;

  const ChatMessage({
    required this.content,
    required this.role,
    this.imagePath,
  });
}
