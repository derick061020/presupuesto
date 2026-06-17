import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gauge semicircular animado, con arco en degradado, glow y marca en el
/// límite base (15). Si [value] supera [max], se pinta en rojo (desborde).
class SemicircleGauge extends StatelessWidget {
  const SemicircleGauge({
    super.key,
    required this.value,
    required this.base,
    required this.max,
    required this.gradient,
    required this.overflowGradient,
    this.center,
  });

  final double value;
  final double base;
  final double max;
  final List<Color> gradient;
  final List<Color> overflowGradient;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final overflow = value > max;
    final colors = overflow ? overflowGradient : gradient;
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.55,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, max)),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (_, animated, _) => CustomPaint(
          painter: _GaugePainter(
            value: animated,
            base: base,
            max: max,
            colors: colors,
            trackColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            tickColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          child: center == null
              ? null
              : Align(
                  alignment: const Alignment(0, 0.35),
                  child: center,
                ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.base,
    required this.max,
    required this.colors,
    required this.trackColor,
    required this.tickColor,
  });

  final double value;
  final double base;
  final double max;
  final List<Color> colors;
  final Color trackColor;
  final Color tickColor;

  static const double _start = math.pi; // izquierda
  static const double _sweep = math.pi; // 180°

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.height * 0.16;
    final radius = size.width / 2 - stroke / 2 - 6;
    final center = Offset(size.width / 2, size.height - stroke / 2 - 4);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Pista de fondo.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, _start, _sweep, false, track);

    final filled = (value / max).clamp(0.0, 1.0);

    if (filled > 0) {
      final shader = SweepGradient(
        startAngle: _start,
        endAngle: _start + _sweep,
        colors: colors,
        transform: const GradientRotation(_start),
      ).createShader(rect);

      // Glow difuso.
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawArc(rect, _start, _sweep * filled, false, glow);

      // Arco principal.
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader;
      canvas.drawArc(rect, _start, _sweep * filled, false, arc);
    }

    // Marca del límite base (ej. 15) sobre la pista.
    final baseFraction = (base / max).clamp(0.0, 1.0);
    final tickAngle = _start + _sweep * baseFraction;
    final inner = radius - stroke / 2 - 2;
    final outer = radius + stroke / 2 + 2;
    final p1 = center +
        Offset(math.cos(tickAngle) * inner, math.sin(tickAngle) * inner);
    final p2 = center +
        Offset(math.cos(tickAngle) * outer, math.sin(tickAngle) * outer);
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, tickPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.base != base ||
      old.max != max ||
      old.colors != colors;
}
