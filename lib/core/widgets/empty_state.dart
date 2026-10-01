import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// Theme-coloured illustration drawn in code (spec §9.9): a big circle, a main icon,
/// two satellite circles and a few sparkles. [seed] varies the offsets per screen.
class EmptyIllustration extends StatefulWidget {
  const EmptyIllustration({super.key, required this.icon, this.seed = 0, this.height = 120});

  final IconData icon;
  final int seed;
  final double height;

  @override
  State<EmptyIllustration> createState() => _EmptyIllustrationState();
}

class _EmptyIllustrationState extends State<EmptyIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = widget.height;
    final rnd = math.Random(widget.seed);
    double jitter(double range) => (rnd.nextDouble() - 0.5) * range;
    final big = h * 0.8;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final dy = reduceMotion(context) ? 0.0 : math.sin(_c.value * 2 * math.pi) * 4;
          return SizedBox(
            height: h,
            width: h * 1.6,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: big,
                    height: big,
                    decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle),
                  ),
                  Positioned(
                    left: h * 0.18 + jitter(10),
                    top: h * 0.08,
                    child: _dot(h * 0.22, cs.tertiaryContainer),
                  ),
                  Positioned(
                    right: h * 0.2 + jitter(10),
                    bottom: h * 0.06,
                    child: _dot(h * 0.16, cs.primaryContainer),
                  ),
                  Positioned(right: h * 0.12, top: h * 0.2 + jitter(8), child: _spark(cs.tertiary, 6)),
                  Positioned(left: h * 0.12 + jitter(8), bottom: h * 0.22, child: _spark(cs.primary, 5)),
                  Positioned(left: h * 0.34, top: h * 0.02, child: _spark(cs.secondary, 4)),
                  Icon(widget.icon, size: 64, color: cs.onSecondaryContainer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dot(double d, Color c) => Container(width: d, height: d, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  Widget _spark(Color c, double d) => Container(width: d, height: d, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.seed = 0,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int seed;

  /// Smaller variant for use inside cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: EdgeInsets.all(compact ? Space.sm : Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyIllustration(icon: icon, seed: seed, height: compact ? 80 : 120),
              const SizedBox(height: Space.md),
              Text(title, style: tt.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: Space.xs),
                Text(message!, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Space.lg),
                FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
