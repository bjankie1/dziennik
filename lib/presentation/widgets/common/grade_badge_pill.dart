import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Canonical MEN 1–6 grade pill with automatic semantic coloring and optional weight badge (`REQ-ARCH-02`).
class GradeBadgePill extends StatelessWidget {
  final String value;
  final double? numericValue;
  final int? weight;
  final double size;
  final VoidCallback? onTap;

  const GradeBadgePill({
    super.key,
    required this.value,
    this.numericValue,
    this.weight,
    this.size = 38,
    this.onTap,
  });

  static (Color bg, Color fg) resolveGradeColors(String rawValue, double? numeric) {
    final numVal = numeric ?? double.tryParse(rawValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    if (numVal >= 4.75 || rawValue.startsWith('5') || rawValue.startsWith('6')) {
      return (AppColors.secondaryContainer, AppColors.onSecondaryContainer);
    }
    if (numVal >= 3.75 || rawValue.startsWith('4')) {
      return (AppColors.primaryFixed, AppColors.onPrimaryFixed);
    }
    if (numVal >= 2.75 || rawValue.startsWith('3')) {
      return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
    }
    if (numVal > 0 || rawValue.startsWith('1') || rawValue.startsWith('2') || rawValue.toLowerCase() == 'np' || rawValue.toLowerCase() == 'bz') {
      return (AppColors.errorContainer, AppColors.onErrorContainer);
    }
    return (AppColors.surfaceContainerHigh, AppColors.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = resolveGradeColors(value, numericValue);

    final badge = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: size * 0.39,
              fontWeight: FontWeight.w900,
              color: fgColor,
              height: 1.05,
            ),
          ),
          if (weight != null && weight! > 0 && size >= 36)
            Text(
              'w:$weight',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: fgColor.withValues(alpha: 0.78),
                height: 1.0,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size * 0.28),
      child: badge,
    );
  }
}
