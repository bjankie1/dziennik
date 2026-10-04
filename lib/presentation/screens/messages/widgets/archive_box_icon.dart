import 'package:flutter/material.dart';

/// Wektorowa ikona archiwizacji / przywracania niezależna od pamięci podręcznej
/// czcionki MaterialIcons w przeglądarce.
class ArchiveBoxIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool isUnarchive;

  const ArchiveBoxIcon({
    super.key,
    this.size = 16,
    required this.color,
    this.isUnarchive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArchiveBoxPainter(
          color: color,
          isUnarchive: isUnarchive,
        ),
      ),
    );
  }
}

class _ArchiveBoxPainter extends CustomPainter {
  final Color color;
  final bool isUnarchive;

  const _ArchiveBoxPainter({
    required this.color,
    required this.isUnarchive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = (w * 0.115).clamp(1.3, 2.0);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Górna pokrywa pudełka (lid)
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.14, w * 0.80, h * 0.20),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(lidRect, paint);

    // 2. Dolny korpus pudełka (body)
    final bodyPath = Path()
      ..moveTo(w * 0.16, h * 0.34)
      ..lineTo(w * 0.16, h * 0.78)
      ..quadraticBezierTo(w * 0.16, h * 0.86, w * 0.24, h * 0.86)
      ..lineTo(w * 0.76, h * 0.86)
      ..quadraticBezierTo(w * 0.84, h * 0.86, w * 0.84, h * 0.78)
      ..lineTo(w * 0.84, h * 0.34);
    canvas.drawPath(bodyPath, paint);

    // 3. Strzałka wewnątrz pudełka (w dół = archiwizuj, w górę = przywróć)
    final cx = w * 0.50;
    final arrowTop = h * 0.46;
    final arrowBottom = h * 0.73;
    final wingOffset = w * 0.13;

    final arrowPath = Path()
      ..moveTo(cx, arrowTop)
      ..lineTo(cx, arrowBottom);

    if (isUnarchive) {
      arrowPath
        ..moveTo(cx - wingOffset, arrowTop + wingOffset * 0.85)
        ..lineTo(cx, arrowTop)
        ..lineTo(cx + wingOffset, arrowTop + wingOffset * 0.85);
    } else {
      arrowPath
        ..moveTo(cx - wingOffset, arrowBottom - wingOffset * 0.85)
        ..lineTo(cx, arrowBottom)
        ..lineTo(cx + wingOffset, arrowBottom - wingOffset * 0.85);
    }

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ArchiveBoxPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isUnarchive != isUnarchive;
  }
}
