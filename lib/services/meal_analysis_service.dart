import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../providers/meal_scan_provider.dart';

class MealAnalysisService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<MealData> analyzeMealImage(String imagePath) async {
    if (ApiKeys.openAiApiKey.isEmpty) {
      throw Exception(
        'OpenAI API key is missing. Check lib/config/api_keys.dart.',
      );
    }

    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.openAiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '''Analyze this food image and provide nutritional information in JSON format:

{
  "name": "short name of the dish",
  "description": "brief description of what you see",
  "calories": estimated total calories (number only),
  "protein": estimated protein in grams (number only),
  "carbs": estimated carbs in grams (number only),
  "fat": estimated fat in grams (number only)
}

Be reasonable with estimates. If it's a large portion, estimate higher. Only respond with valid JSON.'''
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'temperature': 0.2,
        }),
      );

      // NEW: debug logging
      // ignore: avoid_print
      print('🟣 OpenAI meal status: ${response.statusCode}');
      // ignore: avoid_print
      print('🟣 OpenAI meal body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        final mealJson = jsonDecode(content);

        return MealData(
          name: mealJson['name'],
          description: mealJson['description'],
          calories: mealJson['calories'],
          protein: mealJson['protein'],
          carbs: mealJson['carbs'],
          fat: mealJson['fat'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        final msg = errorData['error']?['message'] ??
            'Failed to analyze image: ${response.statusCode}';
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Error analyzing meal: $e');
    }
  }
}
