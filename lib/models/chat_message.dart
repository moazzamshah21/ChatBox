enum MessageRole { user, assistant }

class ChatMessage {
  final String content;
  final MessageRole role;

  const ChatMessage({required this.content, required this.role});
}
