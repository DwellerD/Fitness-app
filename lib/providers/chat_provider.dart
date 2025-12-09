import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../models/coach_persona.dart';
import 'profile_provider.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'meal_scan_provider.dart';
import 'nutrition_provider.dart'; // NEW

class ChatMessage {
  final String content;
  final bool isAI;

  ChatMessage({required this.content, required this.isAI});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final CoachPersona persona;
  final String? pendingProfileUpdateText;

  ChatState({
    required this.messages,
    required this.persona,
    this.isLoading = false,
    this.pendingProfileUpdateText,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    CoachPersona? persona,
    String? pendingProfileUpdateText,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      persona: persona ?? this.persona,
      isLoading: isLoading ?? this.isLoading,
      pendingProfileUpdateText:
          pendingProfileUpdateText ?? this.pendingProfileUpdateText,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final OpenAIService _openAIService;
  final Ref _ref;

  ChatNotifier(this._openAIService, this._ref, CoachPersona persona)
      : super(ChatState(
          messages: [
            ChatMessage(content: persona.greeting, isAI: true),
          ],
          persona: persona,
        ));

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(content: content, isAI: false);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      pendingProfileUpdateText: null,
    );

    try {
      final apiMessages = state.messages.map((msg) {
        return {
          'role': msg.isAI ? 'assistant' : 'user',
          'content': msg.content,
        };
      }).toList();

      final systemPrompt = await _buildSystemPrompt(state.persona);

      final response =
          await _openAIService.sendMessage(apiMessages, systemPrompt);

      final aiMessage = ChatMessage(content: response, isAI: true);

      final proposalText = _extractProfileUpdateProposal(response);

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        pendingProfileUpdateText: proposalText,
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        content:
            'Sorry, I had trouble connecting to the AI. Please try again in a moment.',
        isAI: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        pendingProfileUpdateText: null,
      );
    }
  }

  String? _extractProfileUpdateProposal(String content) {
    final marker = 'Profile Update Proposal:';
    final idx = content.indexOf(marker);
    if (idx == -1) return null;

    final block = content.substring(idx + marker.length).trim();
    if (block.isEmpty) return null;
    return block;
  }

  Future<void> applyPendingProfileUpdate() async {
    final proposal = state.pendingProfileUpdateText;
    if (proposal == null) return;

    final profileAsync = _ref.read(userProfileProvider);
    final firestore = _ref.read(firestoreServiceProvider);

    profileAsync.whenData((existing) async {
      final userId = firestore.currentUserId;
      if (userId == null) return;

      final base = existing ?? UserProfile(userId: userId);
      final updated = _mergeProfileWithProposal(base, proposal);

      await firestore.saveUserProfile(updated);

      state = state.copyWith(pendingProfileUpdateText: null);

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            content:
                'Got it! I\'ve updated your profile with these details so I can personalize advice better.',
            isAI: true,
          ),
        ],
      );
    });
  }

  UserProfile _mergeProfileWithProposal(UserProfile base, String proposal) {
    final lines = proposal.split('\n');
    int? age;
    String? gender;
    double? heightCm;
    double? weightKg;
    String? activityLevel;
    int? calorieGoal;
    int? proteinGoal;
    int? carbsGoal;
    int? fatGoal;
    String? goals;
    String? dietPreference; // NEW

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final key = parts[0].trim();
      final value = parts.sublist(1).join(':').trim();

      switch (key) {
        case 'age':
          age = int.tryParse(value);
          break;
        case 'gender':
          gender = value.isEmpty ? null : value;
          break;
        case 'heightCm':
          heightCm = double.tryParse(value);
          break;
        case 'weightKg':
          weightKg = double.tryParse(value);
          break;
        case 'activityLevel':
          activityLevel = value;
          break;
        case 'calorieGoal':
          calorieGoal = int.tryParse(value);
          break;
        case 'proteinGoal':
          proteinGoal = int.tryParse(value);
          break;
        case 'carbsGoal':
          carbsGoal = int.tryParse(value);
          break;
        case 'fatGoal':
          fatGoal = int.tryParse(value);
          break;
        case 'goals':
          goals = value.isEmpty ? null : value;
          break;
        case 'dietPreference':
          dietPreference = value.isEmpty ? null : value.toLowerCase();
          break;
      }
    }

    return base.copyWith(
      age: age ?? base.age,
      gender: gender ?? base.gender,
      height: heightCm ?? base.height,
      weight: weightKg ?? base.weight,
      activityLevel: activityLevel ?? base.activityLevel,
      calorieGoal: calorieGoal ?? base.calorieGoal,
      proteinGoal: proteinGoal ?? base.proteinGoal,
      carbsGoal: carbsGoal ?? base.carbsGoal,
      fatGoal: fatGoal ?? base.fatGoal,
      goals: goals ?? base.goals,
      dietPreference: dietPreference ?? base.dietPreference,
    );
  }

  Future<String> _buildSystemPrompt(CoachPersona persona) async {
    final profileAsync = _ref.read(userProfileProvider);
    final todaysTotalsAsync = _ref.read(todaysTotalsProvider); // NEW
    String contextText = '';

    profileAsync.whenData((profile) {
      final buf = StringBuffer();

      final now = DateTime.now();
      buf.writeln('Current context:');
      buf.writeln('- Local date/time: $now');
      buf.writeln('- Local weekday number: ${now.weekday} (1=Mon, 7=Sun)');
      buf.writeln('');

      if (profile != null) {
        buf.writeln('User context:');
        if (profile.age != null) buf.writeln('- Age: ${profile.age}');
        if (profile.gender != null) buf.writeln('- Gender: ${profile.gender}');
        if (profile.height != null) {
          buf.writeln(
              '- Height: ${profile.height} ${profile.useMetric ? "cm" : "in"}');
        }
        if (profile.weight != null) {
          buf.writeln(
              '- Weight: ${profile.weight} ${profile.useMetric ? "kg" : "lb"}');
        }
        if (profile.activityLevel != null) {
          buf.writeln('- Activity level: ${profile.activityLevel}');
        }
        if (profile.dietaryRestrictions.isNotEmpty) {
          buf.writeln(
              '- Dietary restrictions: ${profile.dietaryRestrictions.join(", ")}');
        }
        if (profile.dietPreference != null &&
            profile.dietPreference!.trim().isNotEmpty) {
          buf.writeln('- Diet preference: ${profile.dietPreference}');
        }
        if (profile.injuries.isNotEmpty) {
          buf.writeln(
              '- Injuries / limitations: ${profile.injuries.join(", ")}');
        }
        buf.writeln(
            '- Calorie goal: ${profile.calorieGoal} (P/C/F: ${profile.proteinGoal}/${profile.carbsGoal}/${profile.fatGoal} g)');
        if (profile.goals != null && profile.goals!.trim().isNotEmpty) {
          buf.writeln('- User-stated goals / notes: ${profile.goals}');
        }
      }

      contextText = buf.toString();
    });

    // Add today's logged food totals if available
    todaysTotalsAsync.whenData((totals) {
      final cal = totals['calories'] ?? 0;
      final p = totals['protein'] ?? 0;
      final c = totals['carbs'] ?? 0;
      final f = totals['fat'] ?? 0;

      final buf = StringBuffer(contextText);
      buf.writeln('');
      buf.writeln('Today\'s logged nutrition so far:');
      buf.writeln('- Calories eaten: $cal');
      buf.writeln('- Protein: $p g');
      buf.writeln('- Carbs: $c g');
      buf.writeln('- Fat: $f g');

      contextText = buf.toString();
    });

    return '${persona.systemPrompt}\n\n$contextText';
  }
}

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
        (ref, personaId) {
  final persona = CoachPersona.getById(personaId);
  return ChatNotifier(ref.watch(openAIServiceProvider), ref, persona);
});
