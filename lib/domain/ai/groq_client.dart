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

/// Sends chat completions for Clara.
///
/// SECURITY: There are two paths, chosen automatically:
///
///  1. Proxy path (production): if no build-time GROQ_API_KEY is present, the
///     client POSTs to the app's own serverless proxy at [_proxyPath]
///     (Netlify function `clara`). The proxy holds the real Groq key
///     server-side, so the key is NEVER shipped to the browser. This is the
///     default for deployed builds.
///
///  2. Direct path (local dev): if a key is injected at build time via
///     `--dart-define=GROQ_API_KEY=...`, the client talks to Groq directly.
///     This keeps the local `flutter run --dart-define=...` workflow working
///     with no proxy needed.
///
/// The Groq request parameters (model, temperature, max_tokens) are identical
/// on both paths, so Clara's answers are unchanged either way.
class GroqClient {
  GroqClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'qwen/qwen3.8-27b';

  /// Same-origin serverless proxy route (see netlify.toml redirect
  /// `/api/clara` -> the `clara` function).
  static const _proxyPath = '/api/clara';

  /// Optional build-time key. When empty (the default for production web
  /// builds), the client uses the server-side proxy instead.
  static const String _apiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  /// True when a key was baked in at build time (local dev / direct mode).
  bool get _useDirect => _apiKey.isNotEmpty;

  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    int? maxTokens,
  }) async {
    return _useDirect
        ? _completeDirect(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            maxTokens: maxTokens)
        : _completeViaProxy(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            maxTokens: maxTokens);
  }

  // --- Production: call our own serverless proxy (key stays on the server) ---
  Future<String> _completeViaProxy({
    required String systemPrompt,
    required String userMessage,
    int? maxTokens,
  }) async {
    final response = await _http
        .post(
          Uri.parse(_proxyPath),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemPrompt': systemPrompt,
            'userMessage': userMessage,
            if (maxTokens != null) 'maxTokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 60));

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }

    if (response.statusCode == 200) {
      return (body['content'] as String?) ?? '';
    }
    final msg = (body['error'] as String?) ?? response.body;
    throw GroqApiException(response.statusCode, msg);
  }

  // --- Local dev: call Groq directly using the build-time key ---
  Future<String> _completeDirect({
    required String systemPrompt,
    required String userMessage,
    int? maxTokens,
  }) async {
    final response = await _http
        .post(
          Uri.parse(_groqEndpoint),
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
            // Chat answers stay under Groq's free-tier ~1000 output-tokens
            // budget; quizzes/flashcards can request more via [maxTokens]
            // since a longer structured JSON response needs the room.
            'max_tokens': maxTokens ?? 950,
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
