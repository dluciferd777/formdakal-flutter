// lib/widgets/activity_ring_painter.dart - PARLALIK ARTTIRILDI
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

  ActivityRingPainter({
    required this.outerProgress,
    required this.middleProgress,
    required this.innerProgress,
    required this.outerColor,
    required this.middleColor,
    required this.innerColor,
    this.showGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 3.0;
    const spacing = 3.5;

    // Dış halka
    _drawRing(canvas, center, size.width / 2 - strokeWidth / 2, outerProgress, outerColor, strokeWidth, isOuter: true);
    
    // Orta halka
    _drawRing(canvas, center, size.width / 2 - strokeWidth * 1.5 - spacing, middleProgress, middleColor, strokeWidth, isMiddle: true);
    
    // İç halka
    _drawRing(canvas, center, size.width / 2 - strokeWidth * 2.5 - spacing * 2, innerProgress, innerColor, strokeWidth, isInner: true);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress, Color color, double strokeWidth, {bool isOuter = false, bool isMiddle = false, bool isInner = false}) {
    // Arka plan halkası - DAHA GÖRÜNÜR
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.8); // 0.5'ten 0.8'e artırıldı
    backgroundPaint.style = PaintingStyle.stroke;
    backgroundPaint.strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // İlerleme halkası
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1.0 // Kalınlık artırıldı
        ..strokeCap = StrokeCap.round;

      // SÜPER PARLAMA EFEKTİ
      if (showGlow || progress > 0.1) {
        // Progress değerine göre çok güçlü parlama
        double glowIntensity = 5.0 + (progress * 15.0); // 2.0+8.0'dan 5.0+15.0'a artırıldı
        
        // Çoklu glow katmanları
        for (int i = 0; i < 3; i++) {
          final glowPaint = Paint()
            ..color = color.withOpacity(0.6 - (i * 0.2))
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + (i * 2.0)
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowIntensity + (i * 3.0));

          final rect = Rect.fromCircle(center: center, radius: radius);
          canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, glowPaint);
        }
      }
        
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, progressPaint);

      // EKSTRA PARLAMA - Progress çizgisinin üzerine
      if (progress > 0.05) {
        final extraGlowPaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
          
        canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, extraGlowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ActivityRingPainter) {
      return outerProgress != oldDelegate.outerProgress ||
             middleProgress != oldDelegate.middleProgress ||
             innerProgress != oldDelegate.innerProgress ||
             outerColor != oldDelegate.outerColor ||
             middleColor != oldDelegate.middleColor ||
             innerColor != oldDelegate.innerColor ||
             showGlow != oldDelegate.showGlow;
    }
    return true;
  }
}