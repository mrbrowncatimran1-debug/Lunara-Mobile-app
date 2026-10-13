import 'package:flutter/material.dart';

import '../coach.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

Future<T?> _showLunaraSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: LColors.white,
    barrierColor: LColors.scrim,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LRadius.sheet)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: builder(ctx),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Bottom Sheet — "AI Plan"
// ---------------------------------------------------------------------------

/// Returns how many habits were added.
Future<int?> showAiPlanSheet(BuildContext context, AppState s, String goal) {
  return _showLunaraSheet<int>(context, (ctx) => _AiPlanSheet(state: s, goal: goal));
}

class _AiPlanSheet extends StatefulWidget {
  const _AiPlanSheet({required this.state, required this.goal});
  final AppState state;
  final String goal;
  @override
  State<_AiPlanSheet> createState() => _AiPlanSheetState();
}

class _AiPlanSheetState extends State<_AiPlanSheet> {
  int _variant = 0;
  late Plan _plan;
  late List<bool> _picked;
  bool _thinking = true;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    if (!_thinking) setState(() => _thinking = true);
    // A short pause so it feels like Lunara is thinking.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _plan = buildPlan(widget.state, widget.goal, variant: _variant);
      _picked = [true, true, false];
      _thinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = _thinking ? 0 : _picked.where((p) => p).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetGrabber(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lunara’s plan for you'.toUpperCase(), style: LText.overline12),
                  const SizedBox(height: 4),
                  Text(_thinking ? 'Making your plan…' : _plan.title, style: LText.headingSerif24),
                ],
              ),
            ),
            const SizedBox(width: 12),
            RoundIconButton('close', tooltip: 'Close', onTap: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Text(
            'Based on “${widget.goal}” Three tiny habits — keep the ones that feel right.',
            style: LText.body14.copyWith(color: LColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        if (_thinking)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: LColors.plum, backgroundColor: LColors.lavender),
            ),
          )
        else ...[
          for (var i = 0; i < _plan.suggestions.length; i++) ...[
            _SuggestionRow(
              suggestion: _plan.suggestions[i],
              added: _picked[i],
              onTap: () => setState(() => _picked[i] = !_picked[i]),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: LColors.lavender50, borderRadius: BorderRadius.circular(LRadius.tile)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LIcon('sparkle', size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_plan.why, style: LText.caption13.copyWith(color: LColors.plum))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        LButton(
          count == 0 ? 'Pick at least one habit' : 'Add $count ${count == 1 ? 'habit' : 'habits'}',
          large: true,
          expand: true,
          onPressed: count == 0
              ? null
              : () {
                  final chosen = [
                    for (var i = 0; i < _plan.suggestions.length; i++)
                      if (_picked[i]) _plan.suggestions[i],
                  ];
                  widget.state.addSuggestions(chosen);
                  Navigator.pop(context, chosen.length);
                },
        ),
        const SizedBox(height: 16),
        LButton(
          'Adjust the plan',
          type: BtnType.tertiary,
          large: true,
          expand: true,
          onPressed: _thinking
              ? null
              : () {
                  _variant++;
                  _build();
                },
        ),
      ],
    );
  }
}

/// AI Suggestion Row — Added = Yes / No.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.added, required this.onTap});
  final Suggestion suggestion;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(LRadius.card);
    return Material(
      color: LColors.ivory,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconTile(suggestion.icon, color: LColors.lavender),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.name, style: LText.body16Medium),
                    const SizedBox(height: 2),
                    Text(suggestion.subtitle, style: LText.caption13),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LCheckbox(checked: added),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet — "Confirmation"
// ---------------------------------------------------------------------------

Future<void> showPlanAddedSheet(BuildContext context) {
  return _showLunaraSheet<void>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetGrabber(),
        const SizedBox(height: 16),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: LColors.sage, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const LIcon('check', size: 28),
        ),
        const SizedBox(height: 16),
        const Text('Plan added', style: LText.headingSerif24, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          'Your new habits start tomorrow morning. Lunara will check in after a week.',
          textAlign: TextAlign.center,
          style: LText.body16.copyWith(color: LColors.textSecondary),
        ),
        const SizedBox(height: 16),
        LButton('Done', large: true, expand: true, onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Add / edit habit
// ---------------------------------------------------------------------------

const _iconChoices = ['book', 'move', 'water', 'journal', 'breathe', 'leaf', 'moon', 'tea', 'clock', 'star', 'flame', 'sparkle'];
const _schedules = ['Every day', 'Weekdays', '5 days a week', '3 days a week'];
const _slotNames = {DaySlot.morning: 'Morning', DaySlot.afternoon: 'Afternoon', DaySlot.evening: 'Evening'};

Future<void> showHabitEditor(BuildContext context, AppState s, {Habit? habit}) {
  return _showLunaraSheet<void>(context, (ctx) => _HabitEditor(state: s, habit: habit));
}

class _HabitEditor extends StatefulWidget {
  const _HabitEditor({required this.state, this.habit});
  final AppState state;
  final Habit? habit;
  @override
  State<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<_HabitEditor> {
  late final TextEditingController _name;
  late final TextEditingController _cue;
  late final TextEditingController _goal;
  late String _icon;
  late String _schedule;
  late DaySlot _slot;

  bool get _isNew => widget.habit == null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _cue = TextEditingController(text: h?.cue ?? '');
    _goal = TextEditingController(text: h?.goal ?? '');
    _icon = h?.icon ?? 'sparkle';
    _schedule = h?.schedule ?? 'Every day';
    _slot = h?.slot ?? DaySlot.morning;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _cue.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final cue = _cue.text.trim().isEmpty ? _slotNames[_slot]! : _cue.text.trim();
    final goal = _goal.text.trim().isEmpty ? 'Small step' : _goal.text.trim();
    final h = widget.habit;
    if (h == null) {
      widget.state.addHabit(Habit(
        id: 'h${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        icon: _icon,
        schedule: _schedule,
        slot: _slot,
        cue: cue,
        goal: goal,
      ));
    } else {
      h
        ..name = name
        ..icon = _icon
        ..schedule = _schedule
        ..slot = _slot
        ..cue = cue
        ..goal = goal;
      widget.state.updateHabit();
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final h = widget.habit!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LRadius.aiCard)),
        title: const Text('Remove this habit?', style: LText.headingSerif24),
        content: Text('“${h.name}” and its check-ins will be removed.', style: LText.body14),
        actions: [
          LButton('Keep it', type: BtnType.tertiary, onPressed: () => Navigator.pop(ctx, false)),
          LButton('Remove', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.state.deleteHabit(h);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: SheetGrabber()),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text(_isNew ? 'New habit' : 'Edit habit', style: LText.headingSerif24)),
            RoundIconButton('close', tooltip: 'Close', onTap: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 16),
        _Label('Name'),
        _Field(controller: _name, hint: 'e.g. Read 5 pages', autofocus: _isNew),
        const SizedBox(height: 16),
        _Label('Icon'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in _iconChoices)
              GestureDetector(
                onTap: () => setState(() => _icon = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _icon == i ? LColors.lavender : LColors.lavender50,
                    borderRadius: BorderRadius.circular(LRadius.tile),
                    border: Border.all(color: _icon == i ? LColors.plum : Colors.transparent, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: LIcon(i, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _Label('How often'),
        _Chips(options: _schedules, selected: _schedule, onSelect: (v) => setState(() => _schedule = v)),
        const SizedBox(height: 16),
        _Label('Part of the day'),
        _Chips(
          options: _slotNames.values.toList(),
          selected: _slotNames[_slot]!,
          onSelect: (v) => setState(() => _slot = _slotNames.entries.firstWhere((e) => e.value == v).key),
        ),
        const SizedBox(height: 16),
        _Label('Cue (when exactly)'),
        _Field(controller: _cue, hint: 'e.g. After dinner'),
        const SizedBox(height: 16),
        _Label('Goal'),
        _Field(controller: _goal, hint: 'e.g. 5 pages'),
        const SizedBox(height: 24),
        LButton(_isNew ? 'Add habit' : 'Save changes', large: true, expand: true, onPressed: _name.text.trim().isEmpty ? null : _save),
        if (!_isNew) ...[
          const SizedBox(height: 8),
          LButton('Remove habit', type: BtnType.tertiary, large: true, expand: true, onPressed: _delete),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: LText.body14Medium));
}

class _Field extends StatefulWidget {
  const _Field({required this.controller, required this.hint, this.autofocus = false});
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: LColors.white,
        borderRadius: BorderRadius.circular(LRadius.card),
        border: Border.all(color: f ? LColors.plum : LColors.border, width: f ? 1.5 : 1),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        style: LText.body16,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: LText.body16.copyWith(color: LColors.textSecondary),
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            StatusLabel(o, tone: o == selected ? Tone.lavender : Tone.neutral, onTap: () => onSelect(o)),
        ],
      );
}
