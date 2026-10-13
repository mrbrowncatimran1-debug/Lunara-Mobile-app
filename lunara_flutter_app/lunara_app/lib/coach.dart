import 'models.dart';

/// Demo "AI" coach. Everything here runs on the phone with simple rules,
/// so the app works offline. Swap these functions for real API calls later.

const _slotPlural = {DaySlot.morning: 'mornings', DaySlot.afternoon: 'afternoons', DaySlot.evening: 'evenings'};

class Nudge {
  Nudge({required this.habit, required this.message, required this.smallStep, required this.toastTitle});
  final Habit habit;
  final String message;
  final String smallStep; // e.g. "Read for 5 minutes"
  final String toastTitle; // e.g. "Added for tonight"
}

class _Tiny {
  const _Tiny(this.verbPast, this.smallStep, this.smallNote);
  final String verbPast; // "read"
  final String smallStep; // "reading for just 5 minutes"
  final String smallNote; // "Read for 5 minutes"
}

_Tiny _tinyFor(Habit h) {
  switch (h.icon) {
    case 'book':
      return const _Tiny('read', 'reading for just 5 minutes', 'Read for 5 minutes');
    case 'move':
      return const _Tiny('moved', 'a gentle 10-minute walk', 'A 10-minute walk');
    case 'water':
      return const _Tiny('hit your water goal', 'one extra glass with each meal', 'One glass with each meal');
    case 'journal':
      return const _Tiny('journaled', 'writing just one line', 'Write one line');
    case 'breathe':
      return const _Tiny('took a breathing break', 'three slow breaths', 'Three slow breaths');
    case 'moon':
      return const _Tiny('wound down early', 'screens off 15 minutes earlier', 'Screens off 15 minutes earlier');
    default:
      return _Tiny('did “${h.name.toLowerCase()}”', 'a 2-minute version', 'A 2-minute version of ${h.name.toLowerCase()}');
  }
}

String _lowerFirst(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

String _timing(Habit h) {
  final cue = h.cue.trim();
  final lc = cue.toLowerCase();
  final isCue = lc.startsWith('after') || lc.startsWith('before') || lc.startsWith('with');
  final word = {DaySlot.morning: 'tomorrow morning', DaySlot.afternoon: 'this afternoon', DaySlot.evening: 'tonight'}[h.slot]!;
  if (isCue) return h.slot == DaySlot.evening ? '${_lowerFirst(cue)} $word' : _lowerFirst(cue);
  return word;
}

/// The habit that needs a little help today, or null when everything is done.
Nudge? buildNudge(AppState s) {
  final pending = s.habits.where((h) => !h.doneOn(s.today)).toList();
  if (pending.isEmpty) return null;
  pending.sort((a, b) => a.doneInLast(7, s.today).compareTo(b.doneInLast(7, s.today)));
  final h = pending.first;
  final n = h.doneInLast(7, s.today);
  final t = _tinyFor(h);
  final days = n == 1 ? '1 day' : '$n days';
  final start = n == 0 ? 'No ${h.name.toLowerCase()} yet this week — that’s okay.' : 'You ${t.verbPast} $days this week.';
  final title = {DaySlot.morning: 'Added for tomorrow', DaySlot.afternoon: 'Added for this afternoon', DaySlot.evening: 'Added for tonight'}[h.slot]!;
  final cue = h.cue.toLowerCase();
  final isCue = cue.startsWith('after') || cue.startsWith('before') || cue.startsWith('with');
  return Nudge(
    habit: h,
    message: '$start Try ${t.smallStep} ${_timing(h)}.',
    smallStep: isCue ? '${t.smallNote} ${_lowerFirst(h.cue)}.' : '${t.smallNote}.',
    toastTitle: title,
  );
}

class Insight {
  Insight({required this.habit, required this.message, required this.slot, required this.cue, required this.toast});
  final Habit habit;
  final String message;
  final DaySlot slot;
  final String cue;
  final String toast;
}

const _anchor = {
  DaySlot.morning: ('your first cup of tea', 'With morning tea'),
  DaySlot.afternoon: ('your lunch break', 'After lunch'),
  DaySlot.evening: ('dinner', 'After dinner'),
};

String _gerund(Habit h) {
  switch (h.icon) {
    case 'book':
      return 'reading';
    case 'journal':
      return 'journaling';
    case 'move':
      return 'a short walk';
    case 'water':
      return 'a glass of water';
    case 'breathe':
      return 'a breathing break';
    default:
      return _lowerFirst(h.name);
  }
}

/// "Lunara noticed" card on the Progress screen.
Insight? buildInsight(AppState s) {
  if (s.habits.length < 2) return null;
  final best = s.bestSlot();
  final candidates = s.habits.where((h) => h.slot != best && h.id != s.pairedHabitId).toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final c = a.doneInLast(7, s.today).compareTo(b.doneInLast(7, s.today));
    return c != 0 ? c : s.habits.indexOf(b).compareTo(s.habits.indexOf(a));
  });
  final h = candidates.first;
  final anchor = _anchor[best]!;
  return Insight(
    habit: h,
    slot: best,
    cue: anchor.$2,
    message: 'You’re most consistent in the ${_slotPlural[best]}. Try pairing ${_gerund(h)} with ${anchor.$1}.',
    toast: '${h.name} now follows ${anchor.$1}.',
  );
}

class Plan {
  Plan({required this.title, required this.suggestions, required this.why});
  final String title;
  final List<Suggestion> suggestions;
  final String why;
}

const _sets = <String, (String, List<Suggestion>)>{
  'calm': (
    'A calmer week, gently',
    [
      Suggestion('2-minute breathing', 'breathe', DaySlot.morning, 'Right after you wake', '2 minutes'),
      Suggestion('10-minute walk outside', 'leaf', DaySlot.afternoon, 'After lunch', '10 minutes'),
      Suggestion('Screens off by 10:30 pm', 'moon', DaySlot.evening, 'Wind-down', 'By 10:30 pm'),
      Suggestion('Tea without your phone', 'tea', DaySlot.morning, 'With breakfast', '5 minutes'),
      Suggestion('One line of gratitude', 'journal', DaySlot.evening, 'Before bed', '1 line'),
    ]
  ),
  'sleep': (
    'Softer nights, better mornings',
    [
      Suggestion('Screens off by 10:30 pm', 'moon', DaySlot.evening, 'Wind-down', 'By 10:30 pm'),
      Suggestion('Herbal tea after dinner', 'tea', DaySlot.evening, 'After dinner', '1 cup'),
      Suggestion('Same wake-up time', 'clock', DaySlot.morning, 'Every morning', '7:00 am'),
      Suggestion('Morning light for 5 minutes', 'today', DaySlot.morning, 'Right after you wake', '5 minutes'),
      Suggestion('2-minute breathing in bed', 'breathe', DaySlot.evening, 'Lights out', '2 minutes'),
    ]
  ),
  'read': (
    'Room for a few pages',
    [
      Suggestion('Read 5 pages', 'book', DaySlot.evening, 'After dinner', '5 pages'),
      Suggestion('Book by the bed', 'book', DaySlot.evening, 'Instead of your phone', '1 chapter'),
      Suggestion('Read with morning tea', 'tea', DaySlot.morning, 'With breakfast', '10 minutes'),
      Suggestion('Note one idea you liked', 'journal', DaySlot.evening, 'After reading', '1 line'),
    ]
  ),
  'move': (
    'A little more movement',
    [
      Suggestion('Stretch after waking', 'move', DaySlot.morning, 'Right after you wake', '3 minutes'),
      Suggestion('10-minute walk outside', 'leaf', DaySlot.afternoon, 'After lunch', '10 minutes'),
      Suggestion('Take the stairs', 'move', DaySlot.afternoon, 'At work', 'Every time'),
      Suggestion('Dance to one song', 'star', DaySlot.evening, 'While dinner cooks', '1 song'),
    ]
  ),
  'water': (
    'Easy hydration',
    [
      Suggestion('Glass of water on waking', 'water', DaySlot.morning, 'Right after you wake', '1 glass'),
      Suggestion('Water with each meal', 'water', DaySlot.afternoon, 'With lunch', '1 glass'),
      Suggestion('Refill your bottle at 3 pm', 'clock', DaySlot.afternoon, 'Afternoon break', '1 bottle'),
      Suggestion('Swap one coffee for tea', 'tea', DaySlot.morning, 'Second cup', '1 cup'),
    ]
  ),
  'focus': (
    'Gentle focus',
    [
      Suggestion('One 25-minute focus block', 'clock', DaySlot.morning, 'Before email', '25 minutes'),
      Suggestion('Plan tomorrow in 3 lines', 'journal', DaySlot.evening, 'End of day', '3 lines'),
      Suggestion('2-minute desk reset', 'sparkle', DaySlot.afternoon, 'After lunch', '2 minutes'),
      Suggestion('Phone in another room', 'moon', DaySlot.morning, 'During deep work', '1 hour'),
    ]
  ),
  'default': (
    'Small steps, your way',
    [
      Suggestion('2-minute breathing', 'breathe', DaySlot.morning, 'Right after you wake', '2 minutes'),
      Suggestion('10-minute walk outside', 'leaf', DaySlot.afternoon, 'After lunch', '10 minutes'),
      Suggestion('One line in your journal', 'journal', DaySlot.evening, 'Before bed', '1 line'),
      Suggestion('Glass of water on waking', 'water', DaySlot.morning, 'Right after you wake', '1 glass'),
    ]
  ),
};

String _topicFor(String goal) {
  final g = goal.toLowerCase();
  bool any(List<String> words) => words.any(g.contains);
  if (any(['stress', 'calm', 'anx', 'relax', 'overwhelm', 'peace', 'worry'])) return 'calm';
  if (any(['sleep', 'tired', 'rest', 'insomnia', 'night', 'bed'])) return 'sleep';
  if (any(['read', 'book', 'learn'])) return 'read';
  if (any(['move', 'exercise', 'fit', 'walk', 'active', 'energy', 'gym', 'weight', 'run'])) return 'move';
  if (any(['water', 'hydrat', 'drink'])) return 'water';
  if (any(['focus', 'work', 'productiv', 'study', 'procrastinat'])) return 'focus';
  return 'default';
}

/// Builds a plan of 3 tiny habits. [variant] rotates to a different mix
/// ("Adjust the plan").
Plan buildPlan(AppState s, String goal, {int variant = 0}) {
  final entry = _sets[_topicFor(goal)]!;
  final pool = entry.$2;
  final picked = List.generate(3, (i) => pool[(i + variant) % pool.length]);
  final best = s.bestSlot();
  picked.sort((a, b) {
    int rank(Suggestion x) => x.slot == best ? 0 : 1;
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.slot.index.compareTo(b.slot.index);
  });
  return Plan(
    title: entry.$1,
    suggestions: picked,
    why: 'Why these? You’re most consistent in the ${_slotPlural[best]}, so your plan starts there.',
  );
}

/// Short preview under "Create with AI".
List<Suggestion> previewFor(String goal) {
  final t = goal.trim().isEmpty ? 'calm' : _topicFor(goal);
  return _sets[t]!.$2.take(3).toList();
}
