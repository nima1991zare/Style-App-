import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/color_analysis.dart';
import '../models/wardrobe_item.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 2.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class ColorDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool selected;

  const ColorDot(this.color, {super.key, this.size = 28, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Circular score dial, 0..10.
class ScoreDial extends StatelessWidget {
  final double score;
  final double size;

  const ScoreDial({super.key, required this.score, this.size = 150});

  Color _scoreColor(BuildContext context) {
    if (score >= 8) return const Color(0xFF5E8C61);
    if (score >= 6) return Theme.of(context).colorScheme.primary;
    if (score >= 4.5) return const Color(0xFFC08A3E);
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DialPainter(
          progress: (score / 10).clamp(0, 1),
          color: color,
          track: Theme.of(context).colorScheme.outlineVariant,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: color, fontSize: size * 0.26),
              ),
              Text(
                '/ 10',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _DialPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 7;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = track;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color;

    const start = -math.pi * 1.25;
    const sweep = math.pi * 1.5;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep,
        false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
        sweep * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color;
}

/// Thumbnail for a wardrobe item: photo if available, otherwise a color tile.
class ItemThumb extends StatelessWidget {
  final WardrobeItem item;
  final double size;
  final BorderRadius? radius;

  const ItemThumb(this.item, {super.key, this.size = 56, this.radius});

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(14);
    final color = Color(item.colorValue);
    Widget child;
    if (item.imagePath != null && File(item.imagePath!).existsSync()) {
      child = Image.file(File(item.imagePath!), fit: BoxFit.cover);
    } else {
      final bright = color.computeLuminance() > 0.5;
      child = Container(
        color: color,
        alignment: Alignment.center,
        child: Icon(
          categoryIcon(item.category),
          size: size * 0.4,
          color: bright ? Colors.black45 : Colors.white70,
        ),
      );
    }
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

IconData categoryIcon(ItemCategory c) => switch (c) {
      ItemCategory.top => Icons.checkroom,
      ItemCategory.bottom => Icons.straighten,
      ItemCategory.dress => Icons.girl_outlined,
      ItemCategory.outerwear => Icons.layers_outlined,
      ItemCategory.shoes => Icons.snowshoeing_outlined,
      ItemCategory.bag => Icons.shopping_bag_outlined,
      ItemCategory.accessory => Icons.watch_outlined,
    };

/// Row of palette chips with color names.
class PaletteChips extends StatelessWidget {
  final List<PaletteColor> palette;

  const PaletteChips(this.palette, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in palette)
          Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorDot(p.color, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${nameColor(p.color)} · ${(p.fraction * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
