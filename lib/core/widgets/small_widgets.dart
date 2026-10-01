import 'package:flutter/material.dart';

import '../design/theme.dart';
export '../design/theme.dart' show moneyStyle;
import '../design/tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.color, this.padding});
  final String title;
  final Widget? trailing;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color ?? cs.onSurfaceVariant),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.color, this.icon});
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: Space.xs)],
                Flexible(
                  child: Text(value, style: moneyStyle(tt.titleLarge?.copyWith(color: color)), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard `Card.filled` used by Today (spec §9.7).
class TonalCard extends StatelessWidget {
  const TonalCard({super.key, this.title, this.action, required this.child});
  final String? title;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleMedium)),
                    ?action,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Animated progress bar with a numeric label (spec §9.7 / §9.8).
class LabeledProgress extends StatelessWidget {
  const LabeledProgress({super.key, required this.percent, this.label, this.color, this.semanticsLabel});
  final double? percent;
  final String? label;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final value = ((percent ?? 0) / 100).clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: percent == null ? '-' : '${percent!.round()}%',
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : Dur.medium,
              curve: Ease.inPlace,
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 8, color: color),
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(label ?? (percent == null ? '-' : '${percent!.round()}%'), style: moneyStyle(tt.labelMedium)),
        ],
      ),
    );
  }
}

/// Animated check/status circle used for tasks, habits and list items.
class StatusCircle extends StatefulWidget {
  const StatusCircle({
    super.key,
    required this.state,
    required this.onTap,
    this.semanticLabel,
    this.size = 28,
    this.color,
  });

  /// 0 = empty, 1 = half (doing), 2 = done.
  final int state;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double size;
  final Color? color;

  @override
  State<StatusCircle> createState() => _StatusCircleState();
}

class _StatusCircleState extends State<StatusCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: Dur.short);

  @override
  void didUpdateWidget(StatusCircle old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state && MediaQuery.maybeDisableAnimationsOf(context) != true) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? cs.primary;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    final done = widget.state == 2;
    final half = widget.state == 1;
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(_pulse);
    return Semantics(
      button: true,
      checked: done,
      label: widget.semanticLabel,
      child: InkResponse(
        onTap: widget.onTap,
        radius: Layout.minTouch / 2,
        child: SizedBox(
          width: Layout.minTouch,
          height: Layout.minTouch,
          child: Center(
            child: ScaleTransition(
              scale: scale,
              child: AnimatedContainer(
                duration: reduce ? Duration.zero : Dur.short,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color : Colors.transparent,
                  border: Border.all(color: done || half ? color : cs.outline, width: 2),
                ),
                child: done
                    ? Icon(Icons.check, size: widget.size * 0.65, color: cs.onPrimary)
                    : half
                        ? Icon(Icons.timelapse, size: widget.size * 0.6, color: color)
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
