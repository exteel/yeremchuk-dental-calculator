import 'package:flutter/material.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/calculator_graph.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_answer.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';
import 'package:yeremchuk_dental_calculator/theme/app_spacing.dart';

/// ТЗ UX §1–§3 — одне питання на екран, великі кнопки, можливість
/// повернутись назад.
class CalculatorQuestionView extends StatelessWidget {
  const CalculatorQuestionView({
    required this.question,
    required this.canGoBack,
    required this.onBack,
    required this.onAnswer,
    super.key,
  });

  final CalculatorQuestion question;
  final bool canGoBack;
  final VoidCallback onBack;
  final ValueChanged<QuestionOption> onAnswer;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canGoBack)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Назад'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                padding: EdgeInsets.zero,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.text,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final option in question.options) ...[
            _OptionButton(
              option: option,
              onTap: () => onAnswer(option),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.option, required this.onTap});

  final QuestionOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
        child: Text(
          option.label,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
