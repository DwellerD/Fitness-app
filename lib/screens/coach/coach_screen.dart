import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/coach_persona.dart';
import '../../models/plan.dart';
import '../../services/firestore_service.dart';
import '../../providers/meal_scan_provider.dart';
import '../../providers/plans_provider.dart';

class CoachScreen extends ConsumerStatefulWidget {
  final String personaId;
  final String? editingPlanId;

  const CoachScreen({
    super.key,
    this.personaId = 'fitness',
    this.editingPlanId,
  });

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Track if user just said "yes" to saving
  bool _pendingAutoSave = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      // detect "yes, please save it" style replies
      if (_looksLikeYes(message)) {
        _pendingAutoSave = true;
      }
      ref.read(chatProvider(widget.personaId).notifier).sendMessage(message);
      _controller.clear();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  bool _looksLikeYes(String text) {
    final lower = text.toLowerCase();
    const yesPhrases = [
      'yes',
      'yeah',
      'yep',
      'sure',
      'please save',
      'save it',
      'save this',
      'that would be great',
      'sounds good',
      'ok save',
      'okay save',
    ];
    return yesPhrases.any((p) => lower.contains(p));
  }

  void _showPersonaSwitcher() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: CoachPersona.all.map((persona) {
            return ListTile(
              leading: Text(persona.emoji, style: const TextStyle(fontSize: 32)),
              title: Text(persona.name),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoachScreen(
                      personaId: persona.id,
                      editingPlanId: widget.editingPlanId,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCreatePlanDialog() {
    final chatState = ref.watch(chatProvider(widget.personaId));

    final planLikeMessage = _findLatestPlanLikeMessage(chatState);

    final aiContent = planLikeMessage?.content ??
        chatState.messages
            .lastWhere((m) => m.isAI, orElse: () => chatState.messages.first)
            .content;

    showDialog(
      context: context,
      builder: (context) => _CreatePlanDialog(
        aiResponse: aiContent,
        coachType: widget.personaId,
        existingPlanId: widget.editingPlanId,
      ),
    );
  }

  ChatMessage? _findLatestPlanLikeMessage(ChatState chatState) {
    final messages = chatState.messages;
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (!msg.isAI) continue;

      final text = msg.content.toLowerCase();
      final hasDay1 = text.contains('day 1') || text.contains('day one');
      final hasDay2 = text.contains('day 2') || text.contains('day two');
      final hasWeekdays = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ].any((w) => text.contains(w));

      if ((hasDay1 && hasDay2) || hasWeekdays) {
        return msg;
      }
    }
    return null;
  }

  bool _lastMessageLooksLikePlan(ChatState chatState) {
    return _findLatestPlanLikeMessage(chatState) != null;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.personaId));
    final persona = chatState.persona;

    // Auto-open save dialog IF:
    // - user just said "yes" (_pendingAutoSave)
    // - we can find a plan-like AI message
    if (_pendingAutoSave && _findLatestPlanLikeMessage(chatState) != null) {
      _pendingAutoSave = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCreatePlanDialog();
        }
      });
    }

    final quickActions = _buildQuickActionsForPersona(persona.id);
    final hasDetectedPlan = _lastMessageLooksLikePlan(chatState);
    final hasProfileProposal = chatState.pendingProfileUpdateText != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(persona.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(persona.name),
          ],
        ),
        actions: [
          IconButton(
            icon: hasDetectedPlan
                ? const Icon(Icons.task_alt, color: Colors.teal)
                : const Icon(Icons.add_task),
            onPressed:
                chatState.messages.length > 1 ? _showCreatePlanDialog : null,
            tooltip: hasDetectedPlan
                ? 'Plan detected! Tap to save to Plans.'
                : 'Create Plan from Chat',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showPersonaSwitcher(),
          ),
        ],
      ),
      body: Column(
        children: [
          // NEW: profile update banner
          if (hasProfileProposal)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_pin, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your coach suggested updating your profile (age, weight, goals, etc.). Apply these changes?',
                      style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(chatProvider(widget.personaId).notifier)
                          .applyPendingProfileUpdate();
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Quick action chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickActions
                    .map(
                      (qa) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _QuickActionChip(
                          label: qa.label,
                          icon: qa.icon,
                          onTap: () => _controller.text = qa.prefill,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return _MessageBubble(
                  message: message.content,
                  isAI: message.isAI,
                );
              },
            ),
          ),
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Coach is thinking...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          _ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
            isLoading: chatState.isLoading,
          ),
        ],
      ),
    );
  }

  // Small helper model for quick actions
  List<_QuickActionConfig> _buildQuickActionsForPersona(String personaId) {
    switch (personaId) {
      case 'fitness':
        return [
          _QuickActionConfig(
            label: 'Plan workout week',
            icon: Icons.calendar_today,
            prefill: "Create a 4-week workout plan for me. My goals are ",
          ),
          _QuickActionConfig(
            label: 'Log workout',
            icon: Icons.fitness_center,
            prefill: "I just finished this workout: ",
          ),
          _QuickActionConfig(
            label: 'Fix my form',
            icon: Icons.self_improvement,
            prefill: "Can you help me with form tips for ",
          ),
          _QuickActionConfig(
            label: 'Progression help',
            icon: Icons.trending_up,
            prefill: "How should I progress my training for ",
          ),
        ];
      case 'nutrition':
        return [
          _QuickActionConfig(
            label: 'Daily meal plan',
            icon: Icons.restaurant_menu,
            prefill: "Create a full day of eating for me based on my profile.",
          ),
          _QuickActionConfig(
            label: 'Log what I ate',
            icon: Icons.fastfood,
            prefill: "I ate this today: ",
          ),
          _QuickActionConfig(
            label: 'Grocery list',
            icon: Icons.shopping_cart,
            prefill: "Make a grocery list for this meal plan: ",
          ),
          _QuickActionConfig(
            label: 'Macro help',
            icon: Icons.calculate,
            prefill: "Help me adjust my calories and macros for my goals.",
          ),
        ];
      case 'pt':
        return [
          _QuickActionConfig(
            label: 'Pain check',
            icon: Icons.healing,
            prefill: "I'm feeling pain here: ",
          ),
          _QuickActionConfig(
            label: 'Mobility routine',
            icon: Icons.accessibility_new,
            prefill: "Create a daily mobility routine for my injuries.",
          ),
          _QuickActionConfig(
            label: 'Exercise mods',
            icon: Icons.fitness_center,
            prefill: "How can I modify these exercises so they don’t hurt: ",
          ),
          _QuickActionConfig(
            label: 'Warm-up ideas',
            icon: Icons.local_fire_department,
            prefill: "Give me a warm-up routine before training ",
          ),
        ];
      case 'wellness':
        return [
          _QuickActionConfig(
            label: 'Sleep help',
            icon: Icons.bedtime,
            prefill: "I want to improve my sleep. Here’s my current routine: ",
          ),
          _QuickActionConfig(
            label: 'Stress check-in',
            icon: Icons.self_improvement,
            prefill: "I'm feeling stressed because ",
          ),
          _QuickActionConfig(
            label: 'Daily routine',
            icon: Icons.schedule,
            prefill: "Design a balanced daily routine for me.",
          ),
          _QuickActionConfig(
            label: 'Recovery day',
            icon: Icons.spa,
            prefill: "Plan a recovery / self-care day for me.",
          ),
        ];
      default:
        return [
          _QuickActionConfig(
            label: 'Plan week',
            icon: Icons.calendar_today,
            prefill: "Help me plan this week’s workouts.",
          ),
          _QuickActionConfig(
            label: 'Log workout',
            icon: Icons.fitness_center,
            prefill: "I just finished ",
          ),
        ];
    }
  }
}

// Config object for quick actions
class _QuickActionConfig {
  final String label;
  final IconData icon;
  final String prefill;

  _QuickActionConfig({
    required this.label,
    required this.icon,
    required this.prefill,
  });
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.teal[50],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isAI;

  const _MessageBubble({required this.message, required this.isAI});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAI ? Colors.grey[100] : Colors.teal,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isAI ? Colors.black : Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: isLoading ? null : () {},
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: 'Ask anything or log what you did...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (_) => onSend(),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.teal),
              onPressed: isLoading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePlanDialog extends ConsumerStatefulWidget {
  final String aiResponse;
  final String coachType;
  final String? existingPlanId;

  const _CreatePlanDialog({
    required this.aiResponse,
    required this.coachType,
    this.existingPlanId,
  });

  @override
  ConsumerState<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends ConsumerState<_CreatePlanDialog> {
  final _nameController = TextEditingController();
  int _durationWeeks = 4;
  bool _isLoading = false;
  late PlanType _planType;

  final List<String> _weekdayLabels = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  final Set<int> _selectedWeekdays = {0, 2, 4};

  // Single plan per type: we no longer let the user pick among many
  Plan? _existingPlanOfType;

  bool _isSingleDayNutritionPlan = false;

  @override
  void initState() {
    super.initState();
    _planType = _getPlanType(widget.coachType);
    _nameController.text = _defaultNameForCoach(widget.coachType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _defaultNameForCoach(String coachType) {
    switch (coachType) {
      case 'fitness':
        return 'Workout Plan';
      case 'nutrition':
        return 'Meal Plan';
      case 'pt':
        return 'Recovery Plan';
      case 'wellness':
        return 'Wellness Plan';
      default:
        return 'My Plan';
    }
  }

  PlanType _getPlanType(String coachType) {
    switch (coachType) {
      case 'fitness':
        return PlanType.workout;
      case 'nutrition':
        return PlanType.nutrition;
      case 'pt':
        return PlanType.recovery;
      case 'wellness':
        return PlanType.wellness;
      default:
        return PlanType.workout;
    }
  }

  String _extractPlanBody(String raw) {
    final lower = raw.toLowerCase();
    final lines = raw.split('\n');

    final dayStartIndex = lines.indexWhere((line) {
      final l = line.toLowerCase().trim();
      return l.startsWith('day 1') ||
          l.startsWith('day one') ||
          l.startsWith('monday') ||
          l.startsWith('tuesday') ||
          l.startsWith('wednesday') ||
          l.startsWith('thursday') ||
          l.startsWith('friday') ||
          l.startsWith('saturday') ||
          l.startsWith('sunday');
    });

    if (dayStartIndex == -1) {
      return raw.trim();
    }

    return lines.sublist(dayStartIndex).join('\n').trim();
  }

  Future<void> _savePlanReplacingType() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final mustSelectWeekdays =
        _planType != PlanType.nutrition || !_isSingleDayNutritionPlan;
    if (mustSelectWeekdays && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day of the week.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).value?.uid;
      if (userId == null) return;

      final firestore = ref.read(firestoreServiceProvider);
      final now = DateTime.now();

      // 1) Delete any existing plans of this type (enforce one-per-category)
      await firestore.deletePlansByType(_planType);

      // 2) Build new plan
      final planId = const Uuid().v4();
      final planBody = _extractPlanBody(widget.aiResponse);
      final desc =
          planBody.length > 500 ? '${planBody.substring(0, 500)}...' : planBody;
      final days = _generatePlanDays(planBody);

      final newPlan = Plan(
        id: planId,
        userId: userId,
        name: name,
        description: desc,
        coachType: widget.coachType,
        type: _planType,
        goals: const [],
        durationWeeks: _durationWeeks,
        startDate: now,
        endDate: now.add(Duration(days: _durationWeeks * 7)),
        status: PlanStatus.active,
        days: days,
        progress: 0.0,
      );

      // 3) Save new plan
      await firestore.savePlan(newPlan);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan saved! Any previous ${_planType.name} plan was replaced.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PlanDay> _generatePlanDays(String notes) {
    final List<PlanDay> days = [];
    int dayNumber = 1;

    if (_planType == PlanType.nutrition && _isSingleDayNutritionPlan) {
      days.add(PlanDay(
        dayNumber: dayNumber,
        title: 'Day 1 – Meal Plan',
        notes: notes,
        items: const [],
      ));
      return days;
    }

    for (int week = 0; week < _durationWeeks; week++) {
      for (final weekdayIndex in _selectedWeekdays.toList()..sort()) {
        final title = 'Week ${week + 1} – ${_weekdayLabels[weekdayIndex]}';
        days.add(PlanDay(
          dayNumber: dayNumber++,
          title: title,
          notes: notes,
          items: const [],
        ));
      }
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    // We still read plans to know if one exists, but we don’t show a list
    final plansAsync = ref.watch(userPlansProvider);
    final existingPlans = plansAsync.asData?.value
            .where((p) => p.type == _planType)
            .toList() ??
        const <Plan>[];
    _existingPlanOfType =
        existingPlans.isNotEmpty ? existingPlans.first : null;

    final isNutrition = _planType == PlanType.nutrition;

    return AlertDialog(
      title: const Text('Save Plan from Chat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _durationWeeks,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
              items: [1, 2, 4, 6, 8, 12].map((weeks) {
                return DropdownMenuItem(
                  value: weeks,
                  child: Text('$weeks week${weeks == 1 ? '' : 's'}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _durationWeeks = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlanType>(
              value: _planType,
              decoration: const InputDecoration(
                labelText: 'Plan Type',
                border: OutlineInputBorder(),
              ),
              items: PlanType.values.map((t) {
                final label = t.toString().split('.').last;
                return DropdownMenuItem(
                  value: t,
                  child: Text(label[0].toUpperCase() + label.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _planType = value!),
            ),
            const SizedBox(height: 16),
            if (isNutrition)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'This is a single‑day meal plan',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Turn off to repeat on specific weekdays.',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _isSingleDayNutritionPlan,
                    onChanged: (v) {
                      setState(() => _isSingleDayNutritionPlan = v);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            if (!isNutrition || !_isSingleDayNutritionPlan) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Days of the Week',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(_weekdayLabels.length, (index) {
                  final selected = _selectedWeekdays.contains(index);
                  return ChoiceChip(
                    label: Text(_weekdayLabels[index]),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedWeekdays.add(index);
                        } else {
                          _selectedWeekdays.remove(index);
                        }
                      });
                    },
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
            if (_existingPlanOfType != null)
              Text(
                'Note: saving will replace your existing '
                '${_planType.name.toUpperCase()} plan.',
                style: TextStyle(fontSize: 11, color: Colors.red[700]),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePlanReplacingType,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Plan'),
        ),
      ],
    );
  }
}
