import 'package:flutter/material.dart';

import '../coach.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _encouragement(int done, int total) {
    if (total == 0) return 'Add a first tiny habit to get started.';
    if (done == 0) return 'A fresh start. One small step is enough.';
    if (done == total) return 'Everything done today. Rest is part of the rhythm too.';
    if (done * 2 == total) return 'Halfway there already. Gentle progress still counts.';
    if (done * 2 < total) return 'A lovely start. Gentle progress still counts.';
    return 'Almost there. Keep it gentle.';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    final done = s.doneToday();
    final total = s.habits.length;
    final left = total - done;
    final nudge = buildNudge(s);
    final eveningWord = now.hour < 17 ? 'today' : 'this evening';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        // Top bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const BrandLogo(),
            ProfileAvatar(onTap: () => _editName(context, s)),
          ],
        ),
        const SizedBox(height: 24),
        // Greeting
        Text('${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}'.toUpperCase(), style: LText.overline12),
        const SizedBox(height: 4),
        Text('${_greeting()}, ${s.userName}', style: LText.displaySerif32),
        const SizedBox(height: 4),
        Text(_encouragement(done, total), style: LText.body16.copyWith(color: LColors.textSecondary)),
        const SizedBox(height: 24),
        // Daily progress
        LCard(
          child: Row(
            children: [
              ProgressRing(done: done, total: total),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$done of $total habits completed', style: LText.title18),
                    const SizedBox(height: 6),
                    Text(
                      left == 0
                          ? 'All done. Nicely paced.'
                          : '${numberWord(left)} small ${left == 1 ? 'step' : 'steps'} left for $eveningWord.',
                      style: LText.body14.copyWith(color: LColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    StatusLabel(
                      done == total && total > 0
                          ? 'All done'
                          : done * 2 >= total
                              ? 'On track'
                              : 'Warming up',
                      tone: done * 2 >= total ? Tone.sage : Tone.lavender,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _NudgeCard(nudge: nudge),
        const SizedBox(height: 24),
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today’s habits', style: LText.title18),
            Text(left == 0 ? 'All done' : '$left left', style: LText.body14Medium.copyWith(color: LColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 24),
        if (s.habits.isEmpty)
          Text('No habits yet. Open My Habits to add one, or ask Lunara for a plan.', style: LText.body14.copyWith(color: LColors.textSecondary)),
        for (final h in s.habits) ...[
          HabitCheckCard(habit: h),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _editName(BuildContext context, AppState s) async {
    final c = TextEditingController(text: s.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LRadius.aiCard)),
        title: const Text('What should Lunara call you?', style: LText.headingSerif24),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: LText.body16,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          LButton('Cancel', type: BtnType.tertiary, onPressed: () => Navigator.pop(ctx)),
          LButton('Save', onPressed: () => Navigator.pop(ctx, c.text)),
        ],
      ),
    );
    if (name != null) s.rename(name);
  }
}

/// Habit Card on Today: tap the card or checkbox to complete.
class HabitCheckCard extends StatelessWidget {
  const HabitCheckCard({super.key, required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final done = habit.doneOn(s.today);
    final nudged = s.isNudged(habit);
    final subtitle = done
        ? 'Done · ${habit.goal}'
        : nudged
            ? '${habit.cue} · just a small version today'
            : '${habit.cue} · ${habit.goal}';
    return LCard(
      padding: const EdgeInsets.all(16),
      radius: LRadius.card,
      shadow: LShadows.habit,
      onTap: () => s.toggleToday(habit),
      child: Row(
        children: [
          IconTile(habit.icon, color: done ? LColors.sage : LColors.lavender50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name, style: LText.body16Medium),
                const SizedBox(height: 2),
                Text(subtitle, style: LText.caption13),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LCheckbox(checked: done),
        ],
      ),
    );
  }
}

/// AI Coaching Card — type "Nudge".
class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.nudge});
  final Nudge? nudge;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final n = nudge;
    if (n == null) {
      return _AiShell(
        title: 'Lovely work today',
        message: s.habits.isEmpty
            ? 'Tell Lunara what you’d like to change on My Habits, and she’ll suggest a few tiny habits.'
            : 'All ${s.habits.length} habits done. Rest is part of the rhythm too.',
      );
    }
    final accepted = s.isNudged(n.habit);
    final days = s.lastSevenDays();
    return _AiShell(
      title: 'A little nudge from Lunara',
      message: n.message,
      footer: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_short(n.habit.name)} · last 7 days', style: LText.label12, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final d in days) ...[
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: n.habit.doneOn(d) ? LColors.plum : LColors.white,
                              border: n.habit.doneOn(d) ? null : Border.all(color: LColors.checkboxBorder),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(_dayLetters[d.weekday - 1], style: LText.nav11),
                        ],
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          accepted
              ? StatusLabel('Added', tone: Tone.neutral, onTap: s.undoNudge)
              : LButton(
                  'Try this',
                  onPressed: () {
                    s.acceptNudge(n.habit);
                    Toaster.show(n.toastTitle, n.smallStep, onUndo: s.undoNudge);
                  },
                ),
        ],
      ),
    );
  }

  String _short(String name) {
    // "Read 5 pages" -> "Reading" style labels where we can.
    switch (nudge!.habit.icon) {
      case 'book':
        return 'Reading';
      case 'move':
        return 'Movement';
      case 'water':
        return 'Water';
      case 'journal':
        return 'Journal';
      default:
        return name;
    }
  }
}

/// Lavender AI card shell shared by Today and Progress.
class _AiShell extends StatelessWidget {
  const _AiShell({required this.title, required this.message, this.footer});
  final String title;
  final String message;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: LColors.lavender, borderRadius: BorderRadius.circular(LRadius.aiCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiBadge(),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: LText.title16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: LText.body16),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}
