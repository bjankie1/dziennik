import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Nowoczesny, dwupierścieniowy wykres frekwencji (Dual Ring Gauge):
/// - Zewnętrzny pierścień: Frekwencja rozliczona (obecności + usprawiedliwione / wszystkie lekcje)
/// - Wewnętrzny pierścień: Frekwencja fizyczna (obecności / wszystkie lekcje)
class DualRingAttendanceGauge extends StatelessWidget {
  final double physicalPercentage;
  final double settledPercentage;
  final int unexcusedCount;
  final double size;

  const DualRingAttendanceGauge({
    super.key,
    required this.physicalPercentage,
    required this.settledPercentage,
    required this.unexcusedCount,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DualRingPainter(
              physicalProgress: (physicalPercentage / 100).clamp(0.0, 1.0),
              settledProgress: (settledPercentage / 100).clamp(0.0, 1.0),
              hasUnexcused: unexcusedCount > 0,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${settledPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: unexcusedCount > 0
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unexcusedCount > 0 ? '$unexcusedCount nieusp.' : '100% usp.',
                  style: TextStyle(
                    fontSize: size * 0.085,
                    fontWeight: FontWeight.w800,
                    color: unexcusedCount > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF15803D),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualRingPainter extends CustomPainter {
  final double physicalProgress;
  final double settledProgress;
  final bool hasUnexcused;

  _DualRingPainter({
    required this.physicalProgress,
    required this.settledProgress,
    required this.hasUnexcused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -math.pi / 2;

    // Outer ring: Settled Attendance (Rozliczona - obecności + usprawiedliwione)
    final outerRadius = size.width / 2 - 5;
    const outerStrokeWidth = 7.0;

    final outerTrackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth;
    canvas.drawCircle(center, outerRadius, outerTrackPaint);

    final outerProgressPaint = Paint()
      ..color = const Color(0xFF059669) // Emerald green
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = outerStrokeWidth;

    final outerSweepAngle = 2 * math.pi * settledProgress;
    if (settledProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        outerSweepAngle,
        false,
        outerProgressPaint,
      );
    }

    // Inner ring: Physical Presence (Fizyczna obecność)
    final innerRadius = outerRadius - outerStrokeWidth - 3.5;
    const innerStrokeWidth = 5.5;

    final innerTrackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth;
    canvas.drawCircle(center, innerRadius, innerTrackPaint);

    final innerProgressPaint = Paint()
      ..color = const Color(0xFF0284C7) // Sky / Ocean blue for physical presence
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = innerStrokeWidth;

    final innerSweepAngle = 2 * math.pi * physicalProgress;
    if (physicalProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        innerSweepAngle,
        false,
        innerProgressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter oldDelegate) {
    return oldDelegate.physicalProgress != physicalProgress ||
        oldDelegate.settledProgress != settledProgress ||
        oldDelegate.hasUnexcused != hasUnexcused;
  }
}
