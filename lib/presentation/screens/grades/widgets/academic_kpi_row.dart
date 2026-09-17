import 'package:flutter/material.dart';
import 'weighted_average_kpi_card.dart';
import 'grade_distribution_card.dart';

class AcademicKpiRow extends StatelessWidget {
  const AcademicKpiRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        if (isNarrow) {
          return const Column(
            children: [
              WeightedAverageKpiCard(),
              SizedBox(height: 16),
              GradeDistributionCard(),
            ],
          );
        }

        return const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: WeightedAverageKpiCard(),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 8,
                child: GradeDistributionCard(),
              ),
            ],
          ),
        );
      },
    );
  }
}
