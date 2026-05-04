import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ieltsai/ai/model/model_api_adapter.dart';
import 'package:ieltsai/ai/models/ai_request.dart';
import 'package:ieltsai/config/env_config.dart';

class DeepSeekAdapter implements ModelApiAdapter {
  static final Uri _endpoint = Uri.parse(
    'https://api.deepseek.com/chat/completions',
  );

  @override
  Stream<String> streamComplete(AiRequest request) async* {
    if (!EnvConfig.hasDeepSeekApiKey) {
      throw StateError(
        'DEEPSEEK_API_KEY is missing in .env. Please configure it before requesting suggestions.',
      );
    }

    final completion = await _fetchCompletion(request);
    final words = completion
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    for (final word in words) {
      await Future<void>.delayed(const Duration(milliseconds: 35));
      yield '$word ';
    }
  }

  Future<String> _fetchCompletion(AiRequest request) async {
    final payload = <String, dynamic>{
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an IELTS Writing Task 2 inline autocomplete engine. Return only the exact continuation text for insertion.',
        },
        {'role': 'user', 'content': request.prompt},
      ],
      'temperature': 0.6,
      'max_tokens': 120,
      'stream': false,
    };

    final response = await http
        .post(
          _endpoint,
          headers: {
            'Authorization': 'Bearer ${EnvConfig.deepSeekApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'DeepSeek API error (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('DeepSeek API response format is invalid.');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw StateError('DeepSeek API returned no completion choices.');
    }
    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw StateError('DeepSeek API completion choice is invalid.');
    }
    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw StateError('DeepSeek API completion message is missing.');
    }
    final content = message['content']?.toString().trim() ?? '';
    if (content.isEmpty) {
      throw StateError('DeepSeek API returned empty completion text.');
    }
    return content;
  }
}
