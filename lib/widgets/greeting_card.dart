import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/styles.dart';

class GreetingCard extends StatelessWidget {
  final CardStyle style;
  final String message;
  final String toName;
  final String fromName;
  final double fontScale;

  const GreetingCard({
    super.key,
    required this.style,
    required this.message,
    this.toName = '',
    this.fromName = '',
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final pad = w * 0.12;
          final textWidth = w - pad * 2;
          final small = TextStyle(
            color: style.text.withValues(alpha: 0.85),
            fontSize: w / 22,
            fontWeight: FontWeight.w500,
            height: 1.4,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: style.colors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MotifPainter(style.motif, style.accent)),
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    children: [
                      if (toName.trim().isNotEmpty)
                        Text(
                          'إلى: ${toName.trim()}',
                          style: small,
                          textAlign: TextAlign.center,
                        ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: textWidth,
                              child: Text(
                                message.trim().isEmpty
                                    ? 'اكتب تهنئتك هنا'
                                    : message.trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: style.text,
                                  fontSize: w / 13 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  height: 1.6,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (fromName.trim().isNotEmpty)
                        Text(
                          'مع تحيات: ${fromName.trim()}',
                          style: small,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MotifPainter extends CustomPainter {
  final Motif motif;
  final Color accent;

  _MotifPainter(this.motif, this.accent);

  Paint _fill(double alpha) => Paint()
    ..color = accent.withValues(alpha: alpha)
    ..style = PaintingStyle.fill;

  Paint _stroke(double alpha, double width) => Paint()
    ..color = accent.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  @override
  void paint(Canvas canvas, Size size) {
    switch (motif) {
      case Motif.crescent:
        _crescent(canvas, size);
        _stars(canvas, size, count: 14, alpha: 0.5);
        break;
      case Motif.stars:
        _stars(canvas, size, count: 22, alpha: 0.35);
        break;
      case Motif.confetti:
        _confetti(canvas, size);
        break;
      case Motif.waves:
        _waves(canvas, size);
        break;
      case Motif.hearts:
        _hearts(canvas, size);
        break;
      case Motif.frame:
        _frame(canvas, size);
        break;
      case Motif.dots:
        _dots(canvas, size);
        _frame(canvas, size);
        break;
    }
  }

  void _crescent(Canvas canvas, Size size) {
    final r = size.width * 0.16;
    final c = Offset(size.width * 0.22, size.height * 0.16);
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: c + Offset(r * 0.45, -r * 0.2), radius: r * 0.9));
    final moon = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(moon, _fill(0.9));
  }

  Path _starPath(Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = center +
          Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  void _stars(Canvas canvas, Size size,
      {required int count, required double alpha}) {
    final rnd = math.Random(7);
    for (var i = 0; i < count; i++) {
      final p = Offset(rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height);
      final r = size.width * (0.008 + rnd.nextDouble() * 0.018);
      canvas.drawPath(_starPath(p, r), _fill(alpha + rnd.nextDouble() * 0.3));
    }
  }

  void _confetti(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 40; i++) {
      final p = Offset(rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height);
      final s = size.width * (0.012 + rnd.nextDouble() * 0.014);
      final paint = _fill(0.25 + rnd.nextDouble() * 0.4);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, s * 0.6, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * 1.8, height: s * 0.7),
            paint);
      }
      canvas.restore();
    }
  }

  void _waves(Canvas canvas, Size size) {
    for (var k = 0; k < 3; k++) {
      final base = size.height * (0.80 + k * 0.07);
      final amp = size.height * 0.03;
      final path = Path()..moveTo(0, base);
      const steps = 4;
      final seg = size.width / steps;
      for (var i = 0; i < steps; i++) {
        final x0 = i * seg;
        path.quadraticBezierTo(
            x0 + seg / 2, base + (i.isEven ? -amp : amp), x0 + seg, base);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, _fill(0.12 + k * 0.05));
    }
    _dots(canvas, size, top: true);
  }

  Path _heartPath(Offset c, double s) {
    return Path()
      ..moveTo(c.dx, c.dy + s * 0.35)
      ..cubicTo(c.dx - s, c.dy - s * 0.3, c.dx - s * 0.4, c.dy - s,
          c.dx, c.dy - s * 0.4)
      ..cubicTo(c.dx + s * 0.4, c.dy - s, c.dx + s, c.dy - s * 0.3,
          c.dx, c.dy + s * 0.35)
      ..close();
  }

  void _hearts(Canvas canvas, Size size) {
    final rnd = math.Random(3);
    for (var i = 0; i < 18; i++) {
      final p = Offset(rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height);
      final s = size.width * (0.02 + rnd.nextDouble() * 0.03);
      canvas.drawPath(_heartPath(p, s), _fill(0.15 + rnd.nextDouble() * 0.25));
    }
  }

  void _frame(Canvas canvas, Size size) {
    final m = size.width * 0.05;
    final outer = RRect.fromRectAndRadius(
        Rect.fromLTWH(m, m, size.width - 2 * m, size.height - 2 * m),
        Radius.circular(size.width * 0.03));
    canvas.drawRRect(outer, _stroke(0.8, size.width * 0.006));
    final m2 = m * 1.5;
    final inner = RRect.fromRectAndRadius(
        Rect.fromLTWH(m2, m2, size.width - 2 * m2, size.height - 2 * m2),
        Radius.circular(size.width * 0.02));
    canvas.drawRRect(inner, _stroke(0.45, size.width * 0.003));
    // نجمة صغيرة في كل ركن
    final r = size.width * 0.022;
    for (final c in [
      Offset(m, m),
      Offset(size.width - m, m),
      Offset(m, size.height - m),
      Offset(size.width - m, size.height - m),
    ]) {
      canvas.drawPath(_starPath(c, r), _fill(0.9));
    }
  }

  void _dots(Canvas canvas, Size size, {bool top = false}) {
    final gap = size.width / 14;
    final rows = top ? 3 : 4;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < 4 - row; col++) {
        canvas.drawCircle(
          Offset(size.width - gap * (col + 1), gap * (row + 1)),
          size.width * 0.006,
          _fill(0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) =>
      old.motif != motif || old.accent != accent;
}
