import 'package:flutter/material.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';

/// ТЗ UX §4 — progress without a fixed "крок 3 із 7" label, since the
/// number of questions varies per patient.
class CalculatorProgressBar extends StatelessWidget {
  const CalculatorProgressBar({required this.fraction, super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 6,
        backgroundColor: AppColors.line,
        valueColor: const AlwaysStoppedAnimation(AppColors.teal),
      ),
    );
  }
}
