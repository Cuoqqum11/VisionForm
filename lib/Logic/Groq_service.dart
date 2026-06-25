import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
/// A lightweight service for calling the Groq inference API.
///
/// Groq is used as a fast free fallback when Gemini is rate-limited (429)
/// or unavailable.
///
/// Usage:
///   final response = await GroqService.instance.complete(prompt);
///   if (response != null) { /* use it */ }
class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();
  // ── Configuration ──────────────────────────────────────────────────────────

  /// Paste your Groq API key here.
  /// Get a free key at https://console.groq.com
  final String _apiKey = dotenv.get('KEY') ?? '';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Current recommended model. openai/gpt-oss-20b replaced llama3-8b-8192
  /// which was decommissioned on August 30 2025.
  static const String _model = 'openai/gpt-oss-20b';

  // Increased from 20s to give the larger model enough time.
  static const Duration _timeout = Duration(seconds: 30);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Sends [prompt] to Groq and returns the raw text response.
  ///
  /// Returns null on any failure so callers fall through to the next
  /// waterfall layer without extra try/catch boilerplate.
  Future<String?> complete(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                // System prompt stops the model "thinking out loud" with
                // nutrition math before outputting JSON. That verbose reasoning
                // was consuming all 1024 tokens and truncating the response
                // (finish_reason: length), causing the waterfall to fall through.
                {
                  'role': 'system',
                  'content':
                      'You are a concise JSON API. Output ONLY valid JSON with '
                      'no preamble, no explanations, no calculations, no markdown '
                      'fences. Never show your reasoning. Raw JSON only.',
                },
                {'role': 'user', 'content': prompt},
              ],
              // 2048 gives plenty of room for 3 meal objects or 6 recipe steps.
              // The old 1024 limit was being hit mid-response (finish_reason: length)
              // which truncated the JSON and caused the waterfall to fall through.
              'max_tokens': 2048,
              // Lower temperature = less verbose, more structured output.
              'temperature': 0.3,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Check finish_reason — if it's "length" the response was cut off
        // mid-JSON and will fail to parse. Treat as failure so the waterfall
        // moves to Layer 3 instead of crashing on malformed JSON.
        final finishReason =
            body['choices']?[0]?['finish_reason'] as String? ?? '';
        if (finishReason == 'length') {
          debugPrint(
              '⚠️ Groq hit token limit (finish_reason: length). Treating as failure.');
          return null;
        }

        // OpenAI-compatible response shape:
        // { choices: [ { message: { content: "..." } } ] }
        final content = body['choices']?[0]?['message']?['content'];
        if (content is String && content.isNotEmpty) {
          debugPrint(
              '✅ Groq responded successfully (finish_reason: $finishReason).');
          return content.trim();
        }
        debugPrint('⚠️ Groq returned an empty or unexpected body: $body');
        return null;
      } else {
        debugPrint('⚠️ Groq HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 GroqService.complete() threw: $e');
      return null;
    }
  }
}