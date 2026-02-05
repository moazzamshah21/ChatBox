import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

  String? _apiKey;

  String get apiKey {
    _apiKey ??= dotenv.env['OPENAI_API_KEY'];
    return _apiKey ?? '';
  }

  /// [systemPrompt] is optional. When set, it's sent as the system message so the AI
  /// can adjust tone (e.g. soft, technical, playful) and use user memory.
  Future<String> sendMessage(
    String userMessage,
    List<Map<String, String>> history, {
    String? systemPrompt,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found. Add it to your .env file.');
    }

    final messageMaps = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messageMaps.add({'role': 'system', 'content': systemPrompt.trim()});
    }
    messageMaps.addAll(history);
    messageMaps.add({'role': 'user', 'content': userMessage});

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messageMaps.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) throw Exception('Invalid API response');
    return content.trim();
  }

  /// Sends a message that may include an image (vision). Uses gpt-4o-mini for vision.
  /// [imagePath] is the local file path of the image.
  Future<String> sendMessageWithImage(
    String userMessage,
    String? imagePath,
    List<Map<String, String>> history, {
    String? systemPrompt,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found. Add it to your .env file.');
    }

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt.trim()});
    }
    for (final m in history) {
      messages.add({'role': m['role'], 'content': m['content']});
    }

    dynamic userContent;
    if (imagePath != null && imagePath.isNotEmpty && await File(imagePath).exists()) {
      final bytes = await File(imagePath).readAsBytes();
      final base64 = base64Encode(bytes);
      final mime = imagePath.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      userContent = [
        if (userMessage.trim().isNotEmpty) {'type': 'text', 'text': userMessage.trim()},
        {'type': 'image_url', 'image_url': {'url': 'data:image/$mime;base64,$base64'}},
      ];
    } else {
      userContent = userMessage.trim().isEmpty ? 'What’s in this image?' : userMessage.trim();
    }
    messages.add({'role': 'user', 'content': userContent});

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) throw Exception('Invalid API response');
    return content.trim();
  }

  /// Converts code from one programming language to another using the API.
  Future<String> convertCodeToLanguage(String code, String fromLang, String toLang) async {
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found. Add it to your .env file.');
    }

    final prompt = 'Convert the following $fromLang code to $toLang. '
        'Return only the converted code, no explanations or markdown:\n\n$code';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) throw Exception('Invalid API response');
    return content.trim().replaceFirst(RegExp(r'^```[\w]*\n?'), '').replaceFirst(RegExp(r'\n?```\s*$'), '').trim();
  }
}
