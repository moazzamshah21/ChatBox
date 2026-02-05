import 'chat_message.dart';
import 'game_mode.dart';

class Conversation {
  Conversation({
    required this.id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    this.gameMode,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final GameMode? gameMode;

  String get titleOrPreview {
    if (gameMode != null) return '🎮 ${gameMode!.displayName}';
    if (title.isNotEmpty) return title;
    for (final m in messages) {
      if (m.role == MessageRole.user && m.content.isNotEmpty) {
        final text = m.content.trim();
        return text.length > 40 ? '${text.substring(0, 40)}...' : text;
      }
    }
    return 'New chat';
  }
}
