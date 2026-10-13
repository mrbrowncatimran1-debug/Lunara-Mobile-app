import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme.dart';

/// 24px line icon from the Lunara icon set (assets/icons/<name>.svg).
class LIcon extends StatelessWidget {
  const LIcon(this.name, {super.key, this.size = 24, this.color = LColors.plum});
  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        colorFilter: color == LColors.plum ? null : ColorFilter.mode(color, BlendMode.srcIn),
      );
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo_mark.png', width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.high);
}

/// Brand/Logo: mark + "Lunara" wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});
  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoMark(size: 32),
          SizedBox(width: 8),
          Text('Lunara', style: LText.headingSerif24),
        ],
      );
}

/// Profile Avatar with Dusty Rose ring.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.size = 40, this.onTap});
  final double size;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: LColors.rose, width: 1.5),
          ),
          child: ClipOval(child: Image.asset('assets/images/avatar.png', fit: BoxFit.cover, filterQuality: FilterQuality.high)),
        ),
      );
}

/// White card with border + soft shadow.
class LCard extends StatelessWidget {
  const LCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = LRadius.aiCard,
    this.shadow = LShadows.card,
    this.color = LColors.white,
    this.border = true,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> shadow;
  final Color color;
  final bool border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: r,
        border: border ? Border.all(color: LColors.border) : null,
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum BtnType { primary, secondary, tertiary }

/// Pill button. Large = 52px tall, small = 40px.
class LButton extends StatelessWidget {
  const LButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.type = BtnType.primary,
    this.large = false,
    this.icon,
    this.expand = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final BtnType type;
  final bool large;
  final String? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bg = switch (type) {
      BtnType.primary => LColors.plum,
      BtnType.secondary => LColors.lavender,
      BtnType.tertiary => Colors.transparent,
    };
    final fg = type == BtnType.primary ? LColors.white : LColors.plum;
    final text = large
        ? LText.title16.copyWith(color: fg)
        : LText.button14.copyWith(color: fg);
    final disabled = onPressed == null;
    final r = BorderRadius.circular(LRadius.pill);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onPressed,
          child: Container(
            height: large ? 52 : 40,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: large ? 24 : 16),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  LIcon(icon!, size: large ? 20 : 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label, style: text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum Tone { sage, lavender, rose, neutral }

/// Status Label pill.
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.text, {super.key, this.tone = Tone.sage, this.onTap});
  final String text;
  final Tone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      Tone.sage => LColors.sage,
      Tone.lavender => LColors.lavender,
      Tone.rose => LColors.rose50,
      Tone.neutral => LColors.white,
    };
    final r = BorderRadius.circular(LRadius.pill);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: tone == Tone.neutral ? const BorderSide(color: LColors.border) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(text, style: LText.label12),
        ),
      ),
    );
  }
}

/// Round checkbox — sage with check when done.
class LCheckbox extends StatelessWidget {
  const LCheckbox({super.key, required this.checked});
  final bool checked;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? LColors.sage : LColors.white,
          border: checked ? null : Border.all(color: LColors.checkboxBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: checked ? const LIcon('check', size: 18) : null,
      );
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color = LColors.lavender50, this.size = 40, this.iconSize = 20, this.round = false});
  final String icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool round;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(round ? LRadius.pill : LRadius.tile),
        ),
        alignment: Alignment.center,
        child: LIcon(icon, size: iconSize),
      );
}

/// Plum circle with a white sparkle — marks AI content.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.size = 28, this.iconSize = 16});
  final double size;
  final double iconSize;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: LColors.plum, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: LIcon('sparkle', size: iconSize, color: LColors.white),
      );
}

/// Progress Ring (96px) with "2/4 · done" in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.done, required this.total, this.size = 96});
  final int done;
  final int total;
  final double size;
  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : done / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$done/$total', style: LText.title18),
                Text('done', style: LText.label12.copyWith(color: LColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = LColors.lavender
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * pi, false, track);
    if (value > 0) {
      final arc = Paint()
        ..color = LColors.plum
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, 2 * pi * value.clamp(0.0, 1.0), false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

/// Bottom Navigation: Today · Progress · My Habits.
class LBottomNav extends StatelessWidget {
  const LBottomNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [('today', 'Today'), ('progress', 'Progress'), ('habits', 'My Habits')];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LColors.white,
        border: Border(top: BorderSide(color: LColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: SizedBox(
                    width: 88,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 32,
                          decoration: BoxDecoration(
                            color: i == index ? LColors.lavender : Colors.transparent,
                            borderRadius: BorderRadius.circular(LRadius.pill),
                          ),
                          alignment: Alignment.center,
                          child: Opacity(opacity: i == index ? 1 : 0.72, child: LIcon(_tabs[i].$1)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabs[i].$2,
                          style: LText.nav11.copyWith(color: i == index ? LColors.plum : LColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plum toast with sparkle icon and optional Undo.
class LToast extends StatelessWidget {
  const LToast({super.key, required this.title, required this.body, this.onUndo});
  final String title;
  final String body;
  final VoidCallback? onUndo;
  @override
  Widget build(BuildContext context) => Material(
        color: LColors.plum,
        borderRadius: BorderRadius.circular(LRadius.card),
        elevation: 6,
        shadowColor: const Color(0x3349334F),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const LIcon('sparkle', size: 20, color: LColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: LText.title16.copyWith(color: LColors.white)),
                    const SizedBox(height: 2),
                    Text(body, style: LText.body14.copyWith(color: LColors.white)),
                  ],
                ),
              ),
              if (onUndo != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onUndo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Undo', style: LText.button14.copyWith(color: LColors.rose)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(color: LColors.lavender, borderRadius: BorderRadius.circular(3)),
      );
}

/// Round 40px button with an icon (close, edit).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton(this.icon, {super.key, required this.onTap, this.color = LColors.ivory, this.size = 40, this.iconSize = 20, this.tooltip});
  final String icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final double iconSize;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: LIcon(icon, size: iconSize))),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

String numberWord(int n) {
  const words = ['No', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'];
  return n < words.length ? words[n] : '$n';
}
