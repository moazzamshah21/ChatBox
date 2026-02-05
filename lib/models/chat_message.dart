enum MessageRole { user, assistant }

class ChatMessage {
  final String content;
  final MessageRole role;
  /// Local file path: user = attached image (vision API); assistant = generated image.
  final String? imagePath;

  const ChatMessage({
    required this.content,
    required this.role,
    this.imagePath,
  });
}
