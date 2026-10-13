import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Part of the day a habit (or a check-in) belongs to.
enum DaySlot { morning, afternoon, evening }

DaySlot slotForHour(int hour) {
  if (hour < 12) return DaySlot.morning;
  if (hour < 17) return DaySlot.afternoon;
  return DaySlot.evening;
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar-safe "n days before d" (no daylight-saving surprises).
DateTime minusDays(DateTime d, int n) => DateTime(d.year, d.month, d.day - n);

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.schedule,
    required this.slot,
    required this.cue,
    required this.goal,
    Map<String, int>? checkins,
  }) : checkins = checkins ?? {};

  final String id;
  String name;

  /// Key of an SVG in assets/icons (book, move, water, ...).
  String icon;

  /// "Every day", "5 days a week", ...
  String schedule;
  DaySlot slot;

  /// When it happens — "After dinner", "Before bed", "Morning".
  String cue;

  /// Size of the habit — "5 pages", "8 glasses", "20-minute walk".
  String goal;

  /// day key -> slot index of the check-in.
  final Map<String, int> checkins;

  bool doneOn(DateTime d) => checkins.containsKey(dayKey(d));

  int doneInLast(int days, DateTime today) {
    var n = 0;
    for (var i = 0; i < days; i++) {
      if (doneOn(minusDays(today, i))) n++;
    }
    return n;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'schedule': schedule,
        'slot': slot.index,
        'cue': cue,
        'goal': goal,
        'checkins': checkins,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String,
        schedule: j['schedule'] as String,
        slot: DaySlot.values[(j['slot'] as num).toInt()],
        cue: j['cue'] as String,
        goal: (j['goal'] as String?) ?? '',
        checkins: (j['checkins'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}

/// A suggestion from the (demo) AI coach.
class Suggestion {
  const Suggestion(this.name, this.icon, this.slot, this.cue, this.goal);
  final String name;
  final String icon;
  final DaySlot slot;
  final String cue;
  final String goal;

  String get subtitle {
    const slotName = {DaySlot.morning: 'Morning', DaySlot.afternoon: 'Afternoon', DaySlot.evening: 'Evening'};
    return '${slotName[slot]} · ${cue[0].toLowerCase()}${cue.substring(1)}';
  }
}

/// The whole app state, saved on the phone with shared_preferences.
class AppState extends ChangeNotifier {
  static const _storeKey = 'lunara_state_v1';

  String userName = 'Maya';
  List<Habit> habits = [];

  /// Nudge the user accepted today: habit id + day key.
  String? nudgeHabitId;
  String? nudgeDay;

  /// Habit that was paired by the "Lunara noticed" insight.
  String? pairedHabitId;

  bool loaded = false;

  DateTime get today => dateOnly(DateTime.now());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null) {
      _seedDemoData();
      await _save();
    } else {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        userName = (j['userName'] as String?) ?? 'Maya';
        habits = (j['habits'] as List).map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
        nudgeHabitId = j['nudgeHabitId'] as String?;
        nudgeDay = j['nudgeDay'] as String?;
        pairedHabitId = j['pairedHabitId'] as String?;
      } catch (_) {
        _seedDemoData();
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storeKey,
      jsonEncode({
        'userName': userName,
        'habits': habits.map((h) => h.toJson()).toList(),
        'nudgeHabitId': nudgeHabitId,
        'nudgeDay': nudgeDay,
        'pairedHabitId': pairedHabitId,
      }),
    );
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- actions ----------

  void toggleToday(Habit h) {
    final k = dayKey(today);
    if (h.checkins.containsKey(k)) {
      h.checkins.remove(k);
    } else {
      h.checkins[k] = slotForHour(DateTime.now().hour).index;
    }
    _changed();
  }

  void rename(String name) {
    userName = name.trim().isEmpty ? userName : name.trim();
    _changed();
  }

  void addHabit(Habit h) {
    habits.add(h);
    _changed();
  }

  void addSuggestions(List<Suggestion> list) {
    for (final s in list) {
      habits.add(Habit(
        id: _newId(),
        name: s.name,
        icon: s.icon,
        schedule: 'Every day',
        slot: s.slot,
        cue: s.cue,
        goal: s.goal,
      ));
    }
    _changed();
  }

  void updateHabit() => _changed();

  void deleteHabit(Habit h) {
    habits.removeWhere((e) => e.id == h.id);
    if (nudgeHabitId == h.id) nudgeHabitId = null;
    _changed();
  }

  void acceptNudge(Habit h) {
    nudgeHabitId = h.id;
    nudgeDay = dayKey(today);
    _changed();
  }

  void undoNudge() {
    nudgeHabitId = null;
    nudgeDay = null;
    _changed();
  }

  bool isNudged(Habit h) => nudgeHabitId == h.id && nudgeDay == dayKey(today);

  /// Moves a habit next to the user's best part of the day.
  void pairHabit(Habit h, DaySlot slot, String cue) {
    h.slot = slot;
    h.cue = cue;
    pairedHabitId = h.id;
    _changed();
  }

  void unpair(Habit h, DaySlot oldSlot, String oldCue) {
    h.slot = oldSlot;
    h.cue = oldCue;
    pairedHabitId = null;
    _changed();
  }

  // ---------- numbers for the screens ----------

  int doneToday() => habits.where((h) => h.doneOn(today)).length;

  int countOn(DateTime d) => habits.where((h) => h.doneOn(d)).length;

  List<DateTime> lastSevenDays() => List.generate(7, (i) => minusDays(today, 6 - i));

  int weekCheckins() => lastSevenDays().fold(0, (sum, d) => sum + countOn(d));

  int currentStreak() {
    var d = today;
    // Today without check-ins yet does not break the streak.
    if (countOn(d) == 0) d = minusDays(d, 1);
    var n = 0;
    while (countOn(d) > 0) {
      n++;
      d = minusDays(d, 1);
    }
    return n;
  }

  int bestStreak() {
    final days = <DateTime>{};
    for (final h in habits) {
      for (final k in h.checkins.keys) {
        days.add(DateTime.parse(k));
      }
    }
    if (days.isEmpty) return 0;
    final sorted = days.toList()..sort();
    var best = 1, run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = (sorted[i].difference(sorted[i - 1]).inHours / 24).round();
      run = gap == 1 ? run + 1 : 1;
      best = max(best, run);
    }
    return max(best, currentStreak());
  }

  /// Share of check-ins per part of day over the last 7 days.
  Map<DaySlot, double> slotSplit() {
    final counts = {for (final s in DaySlot.values) s: 0};
    var total = 0;
    for (final d in lastSevenDays()) {
      for (final h in habits) {
        final v = h.checkins[dayKey(d)];
        if (v != null) {
          counts[DaySlot.values[v]] = counts[DaySlot.values[v]]! + 1;
          total++;
        }
      }
    }
    if (total == 0) return {for (final s in DaySlot.values) s: 0};
    return counts.map((k, v) => MapEntry(k, v / total));
  }

  DaySlot bestSlot() {
    final split = slotSplit();
    var best = DaySlot.morning;
    for (final s in DaySlot.values) {
      if (split[s]! > split[best]!) best = s;
    }
    return best;
  }

  Habit? mostConsistent() {
    if (habits.isEmpty) return null;
    final list = [...habits]..sort((a, b) => b.doneInLast(7, today).compareTo(a.doneInLast(7, today)));
    return list.first;
  }

  // ---------- demo data ----------

  static int _idCounter = 0;
  String _newId() => 'h${DateTime.now().microsecondsSinceEpoch}${_idCounter++}';

  void _seedDemoData() {
    final read = Habit(
        id: 'read', name: 'Read 5 pages', icon: 'book', schedule: 'Every day',
        slot: DaySlot.evening, cue: 'After dinner', goal: '5 pages');
    final move = Habit(
        id: 'move', name: 'Move your body', icon: 'move', schedule: '5 days a week',
        slot: DaySlot.morning, cue: 'Morning', goal: '20-minute walk');
    final water = Habit(
        id: 'water', name: 'Drink water', icon: 'water', schedule: 'Every day',
        slot: DaySlot.morning, cue: 'Through the day', goal: '8 glasses');
    final journal = Habit(
        id: 'journal', name: 'Evening journal', icon: 'journal', schedule: 'Every day',
        slot: DaySlot.evening, cue: 'Before bed', goal: '3 minutes');

    const m = 0, a = 1, e = 2;
    void mark(Habit h, int daysAgo, int slot) => h.checkins[dayKey(minusDays(today, daysAgo))] = slot;

    // This week (6 days ago .. today): 3, 2, 4, 2, 1, 3, 2 check-ins = 17 of 28.
    mark(move, 6, m); mark(water, 6, m); mark(journal, 6, e);
    mark(read, 5, a); mark(water, 5, m);
    mark(read, 4, e); mark(move, 4, m); mark(water, 4, m); mark(journal, 4, e);
    mark(move, 3, m); mark(water, 3, a);
    mark(read, 2, a);
    mark(move, 1, m); mark(water, 1, m); mark(journal, 1, e);
    mark(move, 0, m); mark(water, 0, m);

    // Older days: a 12-day current streak and a 21-day best streak.
    for (var d = 7; d <= 11; d++) {
      mark(water, d, m);
      if (d.isOdd) mark(move, d, m);
    }
    for (var d = 13; d <= 33; d++) {
      mark(water, d, m);
      if (d % 3 == 0) mark(read, d, e);
    }

    habits = [read, move, water, journal];
    userName = 'Maya';
  }
}
