import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

  String? _apiKey;

  String get apiKey {
    _apiKey ??= dotenv.env['OPENAI_API_KEY'];
    return _apiKey ?? '';
  }

  Future<String> sendMessage(String userMessage, List<Map<String, String>> history) async {
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found. Add it to your .env file.');
    }

    final messages = [
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
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
