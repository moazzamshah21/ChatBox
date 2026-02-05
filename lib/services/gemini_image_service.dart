import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Uses Google Gemini API for text-to-image generation.
/// Requires GEMINI_API_KEY in .env.
class GeminiImageService {
  static const _model = 'gemini-2.0-flash-exp-image-generation';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String? _apiKey;

  String get apiKey {
    _apiKey ??= dotenv.env['GEMINI_API_KEY'];
    return _apiKey ?? '';
  }

  /// Generates an image from [prompt] and saves it to a temp file.
  /// Returns the local file path, or throws on error.
  Future<String> textToImage(String prompt) async {
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found. Add it to your .env file.');
    }
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a description for the image.');
    }

    final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': trimmed}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      }),
    );

    if (response.statusCode != 200) {
      String message = 'API error: ${response.statusCode}';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) {
          message = json['error']?['message'] as String? ?? message;
        }
      } catch (_) {}
      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No image in response');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null) throw Exception('Invalid response structure');

    for (final part in parts) {
      final map = part as Map<String, dynamic>?;
      final inlineData = map?['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final b64 = inlineData['data'] as String?;
        final mime = inlineData['mimeType'] as String? ?? 'image/png';
        if (b64 == null || b64.isEmpty) throw Exception('Empty image data');
        final bytes = base64Decode(b64);
        if (bytes.isEmpty) throw Exception('Empty image bytes');

        final ext = mime.contains('png')
            ? 'png'
            : mime.contains('jpeg') || mime.contains('jpg')
                ? 'jpg'
                : 'png';
        final dir = await getTemporaryDirectory();
        final name = 'gemini_image_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = p.join(dir.path, name);
        await File(path).writeAsBytes(bytes);
        return path;
      }
    }

    throw Exception('No image in response');
  }
}
