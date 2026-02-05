import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/user_memory.dart';
import '../services/memory_service.dart';
import '../services/openai_service.dart';
import '../utils/context_detector.dart';
import '../utils/message_content_parser.dart';
import '../widgets/ai_avatar.dart';
import '../widgets/code_block_view.dart';
import '../widgets/message_reveal.dart';
import '../widgets/typing_indicator.dart';
import '../models/game_mode.dart';
import 'game_mode_screen.dart';
import 'memory_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialGameMode});

  final GameMode? initialGameMode;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Conversation> _conversations = [];
  String? _currentId;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAI = OpenAIService();
  final MemoryService _memoryService = MemoryService();
  bool _isLoading = false;
  UserMemory _userMemory = const UserMemory();
  String? _pendingImagePath;
  late final ImagePicker _imagePicker;

  static const _brandy = Color(0xFFD4A574);
  static const _surfaceHigh = Color(0xFF2C2520);
  static const _surfaceTop = Color(0xFF231C18);
  static const _userBubble = Color(0xFF4A3728);
  static const _onSurface = Color(0xFFEDE6DF);
  static const _onSurfaceVariant = Color(0xFFC4B5A4);

  Conversation? get _current {
    if (_currentId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _currentId);
    } catch (_) {
      return null;
    }
  }

  List<ChatMessage> get _messages => _current?.messages ?? [];

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    // Warm the image_picker platform channel (helps avoid channel-error on Android)
    _imagePicker.retrieveLostData().then((_) {});
    _createNewConversation(widget.initialGameMode);
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    final m = await _memoryService.load();
    if (!mounted) return;
    setState(() => _userMemory = m);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createNewConversation([GameMode? gameMode]) {
    final id = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _conversations.insert(0, Conversation(id: id, title: gameMode != null ? '🎮 ${gameMode.displayName}' : '', gameMode: gameMode));
      _currentId = id;
    });
  }

  void _selectConversation(String id) {
    setState(() => _currentId = id);
    Navigator.of(context).pop(); // close drawer
  }

  void _deleteCurrentConversation() {
    final cur = _current;
    if (cur == null) return;
    _deleteConversation(cur.id);
  }

  void _deleteConversation(String id) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceHigh,
        title: const Text('Delete conversation?', style: TextStyle(color: _onSurface)),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(color: _onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _brandy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE07D6A))),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      final index = _conversations.indexWhere((c) => c.id == id);
      if (index == -1) return;
      setState(() {
        _conversations.removeAt(index);
        if (_currentId == id) {
          _currentId = _conversations.isEmpty ? null : _conversations.first.id;
        }
      });
      if (_currentId == null) _createNewConversation();
    });
  }

  Future<void> _shareCurrentConversation() async {
    final cur = _current;
    if (cur == null || cur.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to share'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surfaceHigh,
        ),
      );
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('AI Chat — ${cur.titleOrPreview}');
    buffer.writeln();
    for (final m in cur.messages) {
      final label = m.role == MessageRole.user ? 'You' : 'Assistant';
      buffer.writeln('$label:');
      buffer.writeln(m.content);
      buffer.writeln();
    }
    await Share.share(buffer.toString(), subject: 'AI Chat conversation');
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final hasImage = _pendingImagePath != null && _pendingImagePath!.isNotEmpty;
    if ((text.isEmpty && !hasImage) || _isLoading || _current == null) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    final imagePath = _pendingImagePath;
    setState(() => _pendingImagePath = null);

    _current!.messages.add(ChatMessage(
      content: text.isEmpty ? (hasImage ? '🖼 [Image]' : '') : text,
      role: MessageRole.user,
      imagePath: imagePath,
    ));
    if (_current!.title.isEmpty) {
      _current!.title = text.isNotEmpty
          ? (text.length > 40 ? '${text.substring(0, 40)}...' : text)
          : '🖼 Photo';
    }
    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      // History for API: all messages except the one we just added (we send that one with optional image)
      final messageCount = _current!.messages.length;
      final history = _current!.messages
          .sublist(0, messageCount - 1)
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final tone = detectTone(text);
      final toneHint = toneSystemPrompt(tone);
      final memorySummary = _userMemory.toSystemPromptSummary();
      final gamePrompt = _current!.gameMode?.systemPrompt;
      final systemPrompt = [
        if (gamePrompt != null) gamePrompt,
        if (memorySummary.isNotEmpty) memorySummary,
        if (toneHint.isNotEmpty) toneHint,
      ].where((s) => s.isNotEmpty).join(' ').trim();
      final system = systemPrompt.isEmpty ? null : systemPrompt;

      final String reply;
      if (imagePath != null) {
        reply = await _openAI.sendMessageWithImage(
          text,
          imagePath,
          history,
          systemPrompt: system,
        );
      } else {
        reply = await _openAI.sendMessage(text, history, systemPrompt: system);
      }

      if (!mounted) return;
      _current!.messages.add(ChatMessage(content: reply, role: MessageRole.assistant));
      setState(() => _isLoading = false);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _current!.messages.add(ChatMessage(content: 'Error: $e', role: MessageRole.assistant));
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add photo',
                style: TextStyle(
                  color: _onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: _brandy),
                title: const Text('Take photo', style: TextStyle(color: _onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(ImageSource.camera));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: _brandy),
                title: const Text('Choose from gallery', style: TextStyle(color: _onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(ImageSource.gallery));
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_paste_rounded, color: _brandy),
                title: const Text('Paste from clipboard', style: TextStyle(color: _onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _pasteImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (file != null && mounted) {
        setState(() => _pendingImagePath = file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _surfaceHigh,
          ),
        );
      }
    }
  }

  Future<void> _pasteImage() async {
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes == null || imageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image in clipboard'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF2C2520),
            ),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'pasted_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(path).writeAsBytes(imageBytes);
      if (mounted) setState(() => _pendingImagePath = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not paste image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _surfaceHigh,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1512),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AiAvatar(
              isThinking: _isLoading,
              size: 34,
              brandy: _brandy,
              background: _userBubble,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _current?.titleOrPreview ?? 'AI Chat',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        backgroundColor: _surfaceTop,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_current != null && _current!.messages.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareCurrentConversation,
              tooltip: 'Share conversation',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deleteCurrentConversation,
              tooltip: 'Delete conversation',
            ),
          ],
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          if (_userMemory.memoryChips.isNotEmpty) _buildMemoryChips(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }
                final msg = _messages[index];
                return MessageReveal(
                  key: ValueKey('${msg.role}_${msg.content.hashCode}_$index'),
                  child: _buildMessageBubble(msg),
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMemoryChips() {
    final chips = _userMemory.memoryChips;
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceHigh.withOpacity(0.6),
        border: Border(bottom: BorderSide(color: _surfaceHigh)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = chips[index];
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: _userBubble.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(color: _onSurface, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _surfaceTop,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Conversations',
                style: TextStyle(
                  color: _onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: _brandy),
              title: const Text('New chat', style: TextStyle(color: _brandy, fontWeight: FontWeight.w600)),
              onTap: () {
                _createNewConversation();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_rounded, color: _onSurfaceVariant),
              title: const Text('Your memory', style: TextStyle(color: _onSurface)),
              subtitle: _userMemory.isEmpty
                  ? null
                  : Text(
                      '${_userMemory.memoryChips.length} thing(s) remembered',
                      style: const TextStyle(color: _onSurfaceVariant, fontSize: 12),
                    ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoryScreen())).then((_) => _loadMemory());
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_esports_rounded, color: _onSurfaceVariant),
              title: const Text('🎮 Game mode', style: TextStyle(color: _onSurface)),
              subtitle: const Text(
                '20 Questions, Guess the word, Would You Rather',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GameModeScreen(
                    onSelectGame: (mode) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(initialGameMode: mode),
                        ),
                      );
                    },
                  ),
                ));
              },
            ),
            const Divider(color: Color(0xFF3D342C)),
            Expanded(
              child: ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final c = _conversations[index];
                  final isSelected = c.id == _currentId;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                      color: isSelected ? _brandy : _onSurfaceVariant,
                      size: 22,
                    ),
                    title: Text(
                      c.titleOrPreview,
                      style: TextStyle(
                        color: isSelected ? _onSurface : _onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      color: _onSurfaceVariant,
                      onPressed: () => _deleteConversation(c.id),
                      tooltip: 'Delete',
                    ),
                    onTap: () => _selectConversation(c.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    final segments = parseMessageContent(msg.content);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [_userBubble, const Color(0xFF3D2E24)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _surfaceHigh,
                    const Color(0xFF352C26),
                    const Color(0xFF2A221D),
                  ],
                ),
          color: null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isUser && msg.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(msg.imagePath!),
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              if (msg.content.isNotEmpty && msg.content != '🖼 [Image]') const SizedBox(height: 10),
            ],
            for (final segment in segments)
              switch (segment) {
                TextSegment(:final text) => (text.isEmpty || (isUser && msg.imagePath != null && text.trim() == '🖼 [Image]'))
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SelectableText(
                          text,
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                CodeSegment(:final code, :final language) => CodeBlockView(
                      code: code,
                      language: language,
                      openAIService: _openAI,
                    ),
              },
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _surfaceHigh,
              const Color(0xFF352C26),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AiAvatar(isThinking: true, size: 28, brandy: _brandy, background: _userBubble),
            const SizedBox(width: 14),
            TypingIndicator(brandy: _brandy, onSurfaceVariant: _onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: 14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _surfaceTop,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pendingImagePath != null) _buildPendingImagePreview(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Material(
                color: _surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _isLoading ? null : _showPhotoSourceSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.add_photo_alternate_rounded, color: _onSurfaceVariant, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Color(0xFF8B7B6A)),
                  ),
                  style: const TextStyle(color: _onSurface, fontSize: 16),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _brandy,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send_rounded, color: Color(0xFF2C1810), size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingImagePreview() {
    final path = _pendingImagePath!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: _surfaceHigh,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _pendingImagePath = null),
                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 20, color: _onSurface)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
