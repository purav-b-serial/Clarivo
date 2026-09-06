import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GroqApiException implements Exception {
  const GroqApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'Groq API error $statusCode: $message';
}

class GroqClient {
  GroqClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'qwen/qwen3.8-27b';

  /// API key injected at build time via --dart-define=GROQ_API_KEY=...
  /// Never read from .env at runtime. Never hardcoded.
  static const String _apiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'GROQ_API_KEY is not set. '
          'Build with: flutter build web --release --dart-define=GROQ_API_KEY=your_key');
    }

    final response = await _http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userMessage},
            ],
            'temperature': 0.3,
            'max_tokens': 2048,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['choices'] as List).first['message']['content'] as String;
    } else {
      String errorMsg;
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMap = err['error'] as Map?;
        errorMsg = (errorMap?['message'] as String?) ?? response.body;
      } catch (_) {
        errorMsg = response.body;
      }
      throw GroqApiException(response.statusCode, errorMsg);
    }
  }
}

final groqClientProvider = Provider<GroqClient>((ref) => GroqClient());
