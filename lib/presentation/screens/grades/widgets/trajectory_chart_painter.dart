import 'package:flutter/material.dart';

class TrajectoryPoint {
  final String label;
  final double value;
  final bool isLatest;

  const TrajectoryPoint({
    required this.label,
    required this.value,
    this.isLatest = false,
  });
}

class TrajectoryChartPainter extends CustomPainter {
  final List<TrajectoryPoint> points;
  final double classAverage;
  final double minY;
  final double maxY;
  final Color primaryColor;
  final Color classAvgColor;
  final Color gridColor;

  const TrajectoryChartPainter({
    required this.points,
    required this.classAverage,
    required this.minY,
    required this.maxY,
    required this.primaryColor,
    required this.classAvgColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Helper to calculate pixel coordinates
    double getY(double val) {
      final ratio = (val - minY) / (maxY - minY);
      return height - (ratio * height);
    }

    double getX(int index) {
      if (points.length <= 1) return width / 2;
      return (index / (points.length - 1)) * width;
    }

    // 1. Draw horizontal subtle dashed grid lines at 4.0, 4.5, 5.0
    final gridValues = [4.0, 4.5, 5.0];
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final val in gridValues) {
      final y = getY(val);
      if (y >= 0 && y <= height) {
        _drawDashedHorizontalLine(canvas, 0, width, y, 4, 4, gridPaint);
      }
    }

    // 2. Draw Class Average Reference Dashed Line (D-10)
    final classAvgY = getY(classAverage);
    final classAvgPaint = Paint()
      ..color = classAvgColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedHorizontalLine(canvas, 0, width, classAvgY, 6, 4, classAvgPaint);

    // 3. Build Cubic Bézier Spline Path
    final path = Path();
    final List<Offset> pixelPoints = [];

    for (int i = 0; i < points.length; i++) {
      pixelPoints.add(Offset(getX(i), getY(points[i].value)));
    }

    path.moveTo(pixelPoints[0].dx, pixelPoints[0].dy);

    for (int i = 0; i < pixelPoints.length - 1; i++) {
      final p0 = pixelPoints[i];
      final p1 = pixelPoints[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(
        controlX,
        p0.dy,
        controlX,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    // 4. Fill Gradient Area Under Curve
    final fillPath = Path.from(path)
      ..lineTo(pixelPoints.last.dx, height)
      ..lineTo(pixelPoints.first.dx, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.22),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Stroke the Main Spline Line
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 6. Draw Measurement Coordinates Dots
    for (int i = 0; i < pixelPoints.length; i++) {
      final offset = pixelPoints[i];
      final pt = points[i];

      if (pt.isLatest) {
        // Outer glow
        canvas.drawCircle(
          offset,
          8.0,
          Paint()..color = primaryColor.withValues(alpha: 0.2),
        );
        // Solid circle with white ring
        canvas.drawCircle(
          offset,
          5.5,
          Paint()..color = primaryColor,
        );
        canvas.drawCircle(
          offset,
          5.5,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      } else {
        // Standard white dot with primary border
        canvas.drawCircle(
          offset,
          4.0,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          offset,
          4.0,
          Paint()
            ..color = primaryColor
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _drawDashedHorizontalLine(
    Canvas canvas,
    double startX,
    double endX,
    double y,
    double dashWidth,
    double dashSpace,
    Paint paint,
  ) {
    double currentX = startX;
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, y),
        Offset((currentX + dashWidth).clamp(startX, endX), y),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TrajectoryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.classAverage != classAverage ||
        oldDelegate.primaryColor != primaryColor;
  }
}
