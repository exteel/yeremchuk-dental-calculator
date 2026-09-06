import 'package:flutter/material.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';
import 'package:yeremchuk_dental_calculator/theme/app_spacing.dart';

/// ТЗ §5.1 — city drives which price column the whole calculator reads
/// from, so it's the very first thing the page asks.
class CalculatorCityView extends StatelessWidget {
  const CalculatorCityView({required this.onSelect, super.key});

  final ValueChanged<ServiceCity> onSelect;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: const Icon(Icons.calculate, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Розрахуйте орієнтовну вартість імплантації',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Оберіть місто — ціни в Івано-Франківську і Чернівцях '
            'відрізняються.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final city in ServiceCity.values) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onSelect(city),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                child: Text(
                  city.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
