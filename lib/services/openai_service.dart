import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class OpenAIService {
  // Back to chat completions
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(
    List<Map<String, String>> messages,
    String systemPrompt,
  ) async {
    if (ApiKeys.openAiApiKey.isEmpty) {
      throw Exception(
        'OpenAI API key is missing. Check lib/config/api_keys.dart.',
      );
    }

    // Convert to chat-completions format: system + user/assistant
    final chatMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ...messages.map((m) => {
            'role': m['role'],
            'content': m['content'],
          }),
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiKeys.openAiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': chatMessages,
        'temperature': 0.7,
      }),
    );

    // NEW: debug logging
    // You’ll see this in your console
    // ignore: avoid_print
    print('🔵 OpenAI chat status: ${response.statusCode}');
    // ignore: avoid_print
    print('🔵 OpenAI chat body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      return content.trim();
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['error']?['message'] ?? 'Unknown error';
      throw Exception('OpenAI API Error: $errorMessage');
    }
  }
}
