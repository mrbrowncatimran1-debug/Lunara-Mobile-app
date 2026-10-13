import 'package:flutter/material.dart';

import '../coach.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.onOpenHabits});
  final VoidCallback onOpenHabits;
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selected = 6; // index in the last-7-days list (6 = today)

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final days = s.lastSevenDays();
    final first = days.first, last = days.last;
    final range = first.month == last.month
        ? '${_monthShort[first.month - 1]} ${first.day} – ${last.day}'
        : '${_monthShort[first.month - 1]} ${first.day} – ${_monthShort[last.month - 1]} ${last.day}';
    final total = s.habits.length;
    final checkins = s.weekCheckins();
    final avg = checkins / 7;
    final split = s.slotSplit();
    final best = s.mostConsistent();
    final bestSlot = s.bestSlot();
    final insight = buildInsight(s);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$range · Last 7 days'.toUpperCase(), style: LText.overline12),
                  const SizedBox(height: 4),
                  const Text('Your progress', style: LText.displaySerif32),
                ],
              ),
            ),
            const StatusLabel('This week', tone: Tone.neutral),
          ],
        ),
        const SizedBox(height: 24),
        // Week selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              _DayPill(
                day: _dayLetters[days[i].weekday - 1],
                date: '${days[i].day}',
                selected: i == _selected,
                allDone: total > 0 && s.countOn(days[i]) == total,
                onTap: () => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Weekly chart
        LCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Habits completed', style: LText.title16),
                        const SizedBox(height: 2),
                        Text('$checkins of ${total * 7} check-ins this week', style: LText.caption13),
                      ],
                    ),
                  ),
                  StatusLabel('Avg ${avg.toStringAsFixed(1)} / day', tone: Tone.lavender),
                ],
              ),
              const SizedBox(height: 16),
              _BarChart(
                counts: [for (final d in days) s.countOn(d)],
                letters: [for (final d in days) _dayLetters[d.weekday - 1]],
                total: total,
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Streaks
        Row(
          children: [
            Expanded(child: _MetricCard(icon: 'flame', tile: LColors.rose50, value: _days(s.currentStreak()), label: 'Current streak')),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(icon: 'star', tile: LColors.lavender50, value: _days(s.bestStreak()), label: 'Best streak')),
          ],
        ),
        const SizedBox(height: 24),
        // Your rhythm
        Text('Your rhythm', style: LText.title18),
        const SizedBox(height: 12),
        LCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RhythmRow(
                icon: best?.icon ?? 'water',
                tile: LColors.sage,
                label: 'Most consistent habit',
                value: best == null ? '—' : '${best.name} · ${best.doneInLast(7, s.today)} of 7 days',
              ),
              const SizedBox(height: 16),
              _RhythmRow(
                icon: bestSlot == DaySlot.evening ? 'moon' : 'today',
                tile: LColors.lavender50,
                label: 'Best time of day',
                value: const {
                  DaySlot.morning: 'Mornings, 7–9 am',
                  DaySlot.afternoon: 'Afternoons, 12–3 pm',
                  DaySlot.evening: 'Evenings, 7–10 pm',
                }[bestSlot]!,
              ),
              const SizedBox(height: 16),
              _SplitBar(split: split),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Legend(color: LColors.plum, text: 'Morning ${(split[DaySlot.morning]! * 100).round()}%'),
                  _Legend(color: LColors.rose, text: 'Afternoon ${(split[DaySlot.afternoon]! * 100).round()}%'),
                  _Legend(color: LColors.lavender, text: 'Evening ${(split[DaySlot.evening]! * 100).round()}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (insight != null) ...[
          _InsightCard(insight: insight),
          const SizedBox(height: 24),
        ],
        // Supportive note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: LColors.sageNote, borderRadius: BorderRadius.circular(LRadius.card)),
          child: Row(
            children: [
              const LIcon('leaf', size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Missed a day? That’s part of the rhythm. Every check-in still counts.', style: LText.body14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _days(int n) => n == 1 ? '1 day' : '$n days';
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day, required this.date, required this.selected, required this.allDone, required this.onTap});
  final String day;
  final String date;
  final bool selected;
  final bool allDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? LColors.white : LColors.plum;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 64,
        decoration: BoxDecoration(
          color: selected ? LColors.plum : LColors.white,
          borderRadius: BorderRadius.circular(LRadius.pill),
          border: selected ? null : Border.all(color: LColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: LText.nav11.copyWith(color: selected ? LColors.white : LColors.textSecondary)),
            const SizedBox(height: 2),
            Text(date, style: LText.title16.copyWith(color: fg)),
            if (allDone) ...[
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: selected ? LColors.sage : LColors.sage, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.counts, required this.letters, required this.total, required this.selected, required this.onSelect});
  final List<int> counts;
  final List<String> letters;
  final int total;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxY = total < 1 ? 1 : total;
    const plotH = 100.0;
    final gridSteps = maxY <= 4 ? [0, maxY ~/ 2, maxY] : [0, (maxY / 2).round(), maxY];
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          // grid lines + y labels
          for (final g in gridSteps.toSet())
            Positioned(
              left: 0,
              right: 0,
              top: 8 + plotH - plotH * g / maxY - 7,
              child: Row(
                children: [
                  SizedBox(width: 20, child: Text('$g', style: LText.nav11.copyWith(color: LColors.textSecondary))),
                  Expanded(child: Container(height: 1, color: LColors.border)),
                ],
              ),
            ),
          // bars
          Positioned(
            left: 20,
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                for (var i = 0; i < counts.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 8 + plotH,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: plotH * counts[i] / maxY),
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              builder: (context, h, _) => Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.bottomCenter,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: i == selected ? LColors.plum : LColors.lavender,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        topRight: Radius.circular(7),
                                        bottomLeft: Radius.circular(3),
                                        bottomRight: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                  if (i == selected)
                                    Positioned(
                                      bottom: h + 4,
                                      child: Text('${counts[i]}/$total', style: LText.label12),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            letters[i],
                            style: LText.nav11.copyWith(
                              color: i == selected ? LColors.plum : LColors.textSecondary,
                              fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.tile, required this.value, required this.label});
  final String icon;
  final Color tile;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => LCard(
        padding: const EdgeInsets.all(16),
        radius: LRadius.card,
        shadow: LShadows.habit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon, color: tile, size: 36),
            const SizedBox(height: 12),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: LText.number28)),
            const SizedBox(height: 2),
            Text(label, style: LText.caption13),
          ],
        ),
      );
}

class _RhythmRow extends StatelessWidget {
  const _RhythmRow({required this.icon, required this.tile, required this.label, required this.value});
  final String icon;
  final Color tile;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconTile(icon, color: tile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: LText.caption13),
                const SizedBox(height: 2),
                Text(value, style: LText.body16Medium),
              ],
            ),
          ),
        ],
      );
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.split});
  final Map<DaySlot, double> split;
  @override
  Widget build(BuildContext context) {
    final parts = [
      (split[DaySlot.morning]!, LColors.plum),
      (split[DaySlot.afternoon]!, LColors.rose),
      (split[DaySlot.evening]!, LColors.lavender),
    ].where((p) => p.$1 > 0).toList();
    if (parts.isEmpty) {
      return Container(height: 10, decoration: BoxDecoration(color: LColors.border, borderRadius: BorderRadius.circular(5)));
    }
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: (parts[i].$1 * 1000).round().clamp(1, 1000).toInt(),
              child: Container(decoration: BoxDecoration(color: parts[i].$2, borderRadius: BorderRadius.circular(5))),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: LText.caption13),
        ],
      );
}

/// AI Coaching Card — type "Insight".
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
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
              Expanded(child: Text('Lunara noticed', style: LText.title16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.message, style: LText.body16),
          const SizedBox(height: 12),
          Row(
            children: [
              const Flexible(child: StatusLabel('Based on your last 3 weeks', tone: Tone.neutral)),
              const SizedBox(width: 12),
              LButton(
                'Pair them',
                onPressed: () {
                  final h = insight.habit;
                  final oldSlot = h.slot, oldCue = h.cue;
                  s.pairHabit(h, insight.slot, insight.cue);
                  Toaster.show('Paired up', insight.toast, onUndo: () => s.unpair(h, oldSlot, oldCue));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
