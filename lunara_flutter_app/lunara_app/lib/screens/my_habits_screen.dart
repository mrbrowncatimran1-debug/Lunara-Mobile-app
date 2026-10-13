import 'package:flutter/material.dart';

import '../coach.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'sheets.dart';

class MyHabitsScreen extends StatefulWidget {
  const MyHabitsScreen({super.key});
  @override
  State<MyHabitsScreen> createState() => _MyHabitsScreenState();
}

class _MyHabitsScreenState extends State<MyHabitsScreen> {
  final _goal = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _goal.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _goal.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _makePlan(AppState s) async {
    final text = _goal.text.trim().isEmpty ? 'I want to feel less stressed.' : _goal.text.trim();
    _focus.unfocus();
    final added = await showAiPlanSheet(context, s, text);
    if (!mounted || added == null || added == 0) return;
    _goal.clear();
    await showPlanAddedSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final preview = previewFor(_goal.text);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        // Header
        Row(
          children: [
            const Expanded(child: Text('My habits', style: LText.displaySerif32)),
            LButton('Add habit', icon: 'plus', onPressed: () => showHabitEditor(context, s)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Build a routine that feels right for you.', style: LText.body16.copyWith(color: LColors.textSecondary)),
        const SizedBox(height: 24),
        // Habit list
        Text('Your routine · ${s.habits.length} ${s.habits.length == 1 ? 'habit' : 'habits'}'.toUpperCase(), style: LText.overline12),
        const SizedBox(height: 8),
        if (s.habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nothing here yet. Add a habit, or let Lunara suggest a few below.', style: LText.body14.copyWith(color: LColors.textSecondary)),
          ),
        for (final h in s.habits) ...[
          LCard(
            padding: const EdgeInsets.all(16),
            radius: LRadius.card,
            shadow: LShadows.habit,
            onTap: () => showHabitEditor(context, s, habit: h),
            child: Row(
              children: [
                IconTile(h.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: LText.body16Medium),
                      const SizedBox(height: 2),
                      Text('${h.schedule} · ${h.cue}', style: LText.caption13),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                RoundIconButton('edit', color: LColors.lavender50, tooltip: 'Edit', onTap: () => showHabitEditor(context, s, habit: h)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        // Create with AI
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: LColors.lavender, borderRadius: BorderRadius.circular(LRadius.aiCard)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AiBadge(size: 32, iconSize: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create with AI', style: LText.headingSerif24),
                        const SizedBox(height: 4),
                        Text('Tell Lunara what you’d like to change. She’ll suggest 2–3 tiny habits to start with.', style: LText.body14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('What would you like to improve?', style: LText.body14Medium),
              const SizedBox(height: 8),
              _GoalField(controller: _goal, focus: _focus, onSubmit: () => _makePlan(s)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final idea in const ['Sleep better', 'Read more', 'Move more', 'Feel calmer'])
                    StatusLabel(idea, tone: Tone.neutral, onTap: () {
                      _goal.text = 'I want to ${idea[0].toLowerCase()}${idea.substring(1)}.';
                      _goal.selection = TextSelection.collapsed(offset: _goal.text.length);
                    }),
                ],
              ),
              const SizedBox(height: 16),
              LButton('Make my plan', icon: 'sparkle', large: true, expand: true, onPressed: () => _makePlan(s)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: LColors.previewWhite, borderRadius: BorderRadius.circular(LRadius.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preview · Lunara might suggest'.toUpperCase(), style: LText.overline12.copyWith(color: LColors.plum)),
                    for (final p in preview) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          LIcon(p.icon, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p.name, style: LText.caption13.copyWith(color: LColors.plum))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Text Field — default / filled / focused states from the design.
class _GoalField extends StatelessWidget {
  const _GoalField({required this.controller, required this.focus, required this.onSubmit});
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final focused = focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: LColors.white,
        borderRadius: BorderRadius.circular(LRadius.card),
        border: Border.all(color: focused ? LColors.plum : LColors.border, width: focused ? 1.5 : 1),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        focusNode: focus,
        style: LText.body16,
        cursorColor: LColors.plum,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'I want to feel less stressed.',
          hintStyle: LText.body16.copyWith(color: LColors.textSecondary),
        ),
      ),
    );
  }
}
