import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';

class OpenAIService {
  static bool _initialized = false;

  // Initialize with your API key
  static void initialize(String apiKey) {
    if (!_initialized) {
      OpenAI.apiKey = apiKey;
      _initialized = true;
    }
  }

  // Analyze food image and extract nutrition information
  static Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final chat = await OpenAI.instance.chat.create(
        model: 'gpt-4o',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''Analyze this food image and provide nutrition information.
                
Return a JSON object with this structure:
{
  "food_items": [
    {
      "name": "item name",
      "quantity": "estimated quantity",
      "calories": number,
      "protein": number (grams),
      "carbs": number (grams),
      "fat": number (grams)
    }
  ],
  "total_calories": number,
  "total_protein": number,
  "total_carbs": number,
  "total_fat": number,
  "confidence": "high/medium/low"
}

Be specific and provide your best estimates based on visible portion sizes.''',
              ),
              OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
                'data:image/jpeg;base64,$base64Image',
              ),
            ],
          ),
        ],
        responseFormat: {"type": "json_object"},
      );

      final content = chat.choices.first.message.content?.first.text ?? '{}';
      return jsonDecode(content);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  // Chat with AI coach
  static Future<String> chatWithCoach(
    String coachId,
    List<Map<String, String>> conversationHistory,
    String userMessage,
  ) async {
    try {
      final systemPrompts = {
        'nutrition': '''You are a professional nutrition coach. Provide evidence-based nutrition advice, 
meal planning guidance, and help users understand their dietary needs. Be encouraging and supportive.
Keep responses concise and actionable.''',
        'fitness': '''You are an experienced fitness coach. Help users with workout planning, exercise form, 
training progression, and motivation. Tailor advice to their fitness level and goals.
Keep responses concise and actionable.''',
        'wellness': '''You are a wellness and mindfulness coach. Focus on stress management, sleep quality, 
recovery, and mental health. Provide holistic health guidance and encouragement.
Keep responses concise and actionable.''',
        'trainer': '''You are a personal trainer specialized in strength training and muscle building. 
Create workout programs, suggest exercises, and help with progressive overload strategies.
Keep responses concise and actionable.''',
      };

      final messages = [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              systemPrompts[coachId] ?? systemPrompts['fitness']!,
            ),
          ],
        ),
        ...conversationHistory.map((msg) {
          return OpenAIChatCompletionChoiceMessageModel(
            role: msg['role'] == 'user'
                ? OpenAIChatMessageRole.user
                : OpenAIChatMessageRole.assistant,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                msg['content']!,
              ),
            ],
          );
        }),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
          ],
        ),
      ];

      final chat = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: messages,
        maxTokens: 500,
      );

      return chat.choices.first.message.content?.first.text ?? 
          'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      throw Exception('Failed to chat with coach: $e');
    }
  }

  // Generate personalized workout plan
  static Future<Map<String, dynamic>> generateWorkoutPlan({
    required String goal,
    required String experienceLevel,
    required int daysPerWeek,
    required List<String> availableEquipment,
  }) async {
    try {
      final chat = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''Create a ${daysPerWeek}-day workout plan with these parameters:
- Goal: $goal
- Experience Level: $experienceLevel
- Available Equipment: ${availableEquipment.join(', ')}

Return a JSON object with this structure:
{
  "plan_name": "descriptive name",
  "duration_weeks": number,
  "workouts": [
    {
      "day": number,
      "name": "workout name",
      "focus": "muscle group or type",
      "exercises": [
        {
          "name": "exercise name",
          "sets": number,
          "reps": "rep range",
          "rest_seconds": number,
          "notes": "form tips"
        }
      ]
    }
  ]
}''',
              ),
            ],
          ),
        ],
        responseFormat: {"type": "json_object"},
      );

      final content = chat.choices.first.message.content?.first.text ?? '{}';
      return jsonDecode(content);
    } catch (e) {
      throw Exception('Failed to generate workout plan: $e');
    }
  }

  // Generate meal plan
  static Future<Map<String, dynamic>> generateMealPlan({
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    required List<String> dietaryRestrictions,
  }) async {
    try {
      final chat = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''Create a daily meal plan with these targets:
- Calories: ${targetCalories.toInt()} kcal
- Protein: ${targetProtein.toInt()}g
- Carbs: ${targetCarbs.toInt()}g
- Fat: ${targetFat.toInt()}g
- Dietary Restrictions: ${dietaryRestrictions.isEmpty ? 'None' : dietaryRestrictions.join(', ')}

Return a JSON object with this structure:
{
  "meals": [
    {
      "name": "meal name (e.g., Breakfast)",
      "time": "suggested time",
      "foods": [
        {
          "item": "food name",
          "quantity": "amount",
          "calories": number,
          "protein": number,
          "carbs": number,
          "fat": number
        }
      ],
      "total_calories": number,
      "total_protein": number,
      "total_carbs": number,
      "total_fat": number
    }
  ]
}''',
              ),
            ],
          ),
        ],
        responseFormat: {"type": "json_object"},
      );

      final content = chat.choices.first.message.content?.first.text ?? '{}';
      return jsonDecode(content);
    } catch (e) {
      throw Exception('Failed to generate meal plan: $e');
    }
  }
}
