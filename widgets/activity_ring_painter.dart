// lib/widgets/activity_ring_painter.dart - Diğer widget'larla uyumlu hale getirildi
import 'package:flutter/material.dart';
import 'dart:math';

class ActivityRingPainter extends CustomPainter {
  final double outerProgress;
  final double middleProgress;
  final double innerProgress;
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;
  final bool showGlow;
  final double customStrokeWidth;

  ActivityRingPainter({
    required this.outerProgress,
    required this.middleProgress,
    required this.innerProgress,
    required this.outerColor,
    required this.middleColor,
    required this.innerColor,
    this.showGlow = false,
    this.customStrokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final spacing = customStrokeWidth / 2;

    // Dış halka
    _drawRing(canvas, center, size.width / 2 - customStrokeWidth / 2, outerProgress, outerColor, customStrokeWidth);
    
    // Orta halka
    _drawRing(canvas, center, size.width / 2 - customStrokeWidth * 1.5 - spacing, middleProgress, middleColor, customStrokeWidth);
    
    // İç halka
    _drawRing(canvas, center, size.width / 2 - customStrokeWidth * 2.5 - spacing * 2, innerProgress, innerColor, customStrokeWidth);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress, Color color, double strokeWidth) {
    if (radius < 0) return; // Negatif yarıçapı çizme

    // Arka Plan Halkası
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // İlerleme Halkası
    if (progress > 0) {
       final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [color.withOpacity(0.6), color],
          startAngle: -pi / 2,
          endAngle: (2 * pi * progress) - (pi / 2),
          transform: GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Parlama efekti
      if (showGlow) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, glowPaint);
      }
        
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ActivityRingPainter oldDelegate) {
    return outerProgress != oldDelegate.outerProgress ||
           middleProgress != oldDelegate.middleProgress ||
           innerProgress != oldDelegate.innerProgress ||
           outerColor != oldDelegate.outerColor ||
           middleColor != oldDelegate.middleColor ||
           innerColor != oldDelegate.innerColor ||
           showGlow != oldDelegate.showGlow;
  }
}
