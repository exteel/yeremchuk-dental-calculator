import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yeremchuk_dental_calculator/calculator/cubit/implant_calculator_cubit.dart';
import 'package:yeremchuk_dental_calculator/calculator/cubit/implant_calculator_state.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/calculator_graph.dart';
import 'package:yeremchuk_dental_calculator/calculator/services/calculator_analytics.dart';
import 'package:yeremchuk_dental_calculator/calculator/widgets/calculator_city_view.dart';
import 'package:yeremchuk_dental_calculator/calculator/widgets/calculator_progress_bar.dart';
import 'package:yeremchuk_dental_calculator/calculator/widgets/calculator_question_view.dart';
import 'package:yeremchuk_dental_calculator/calculator/widgets/calculator_result_view.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';
import 'package:yeremchuk_dental_calculator/theme/app_spacing.dart';

/// This whole app is the calculator — one standalone page, no site
/// header/footer, deployed on its own so the patient's attention isn't
/// split across nav/footer chrome from the main clinic site.
class ImplantCalculatorScreen extends StatelessWidget {
  const ImplantCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImplantCalculatorCubit(
        analytics: const DebugPrintCalculatorAnalytics(),
        entryPage: Uri.base.toString(),
        utmParams: {
          for (final entry in Uri.base.queryParameters.entries)
            if (entry.key.startsWith('utm_')) entry.key: entry.value,
        },
      ),
      child: const _ImplantCalculatorView(),
    );
  }
}

class _ImplantCalculatorView extends StatefulWidget {
  const _ImplantCalculatorView();

  @override
  State<_ImplantCalculatorView> createState() =>
      _ImplantCalculatorViewState();
}

class _ImplantCalculatorViewState extends State<_ImplantCalculatorView> {
  late final ImplantCalculatorCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Captured eagerly: Provider lookups are unsafe once the element is
    // deactivated, so dispose() can't call context.read() itself.
    _cubit = context.read<ImplantCalculatorCubit>();
  }

  @override
  void dispose() {
    _cubit.logAbandonedIfIncomplete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperDim,
      body: SafeArea(
        child: Column(
          children: [
            const _MinimalHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Center(child: _CalculatorBody(cubit: _cubit)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.centerLeft,
      child: Image.asset('assets/images/logo_mark.png', height: 40),
    );
  }
}

class _CalculatorBody extends StatelessWidget {
  const _CalculatorBody({required this.cubit});

  final ImplantCalculatorCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: BlocBuilder<ImplantCalculatorCubit, ImplantCalculatorState>(
        bloc: cubit,
        builder: (context, state) {
          if (state.currentStepId != CalculatorStep.city) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: CalculatorProgressBar(
                      fraction: state.progressFraction,
                    ),
                  ),
                  _buildStep(context, state),
                ],
              ),
            );
          }
          return _buildStep(context, state);
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context, ImplantCalculatorState state) {
    switch (state.currentStepId) {
      case CalculatorStep.city:
        return CalculatorCityView(onSelect: cubit.selectCity);
      case CalculatorStep.result:
        if (state.result == null || state.city == null) {
          return const SizedBox.shrink();
        }
        return CalculatorResultView(
          result: state.result!,
          city: state.city!,
          archSize: state.archSize,
          phoneSubmitted: state.phoneSubmitted,
          consultationSubmitting: state.consultationSubmitting,
          consultationRequested: state.consultationRequested,
          onPrimaryTierChanged: cubit.setPrimaryTier,
          onSecondaryTierChanged: cubit.setSecondaryTier,
          onArchSizeChanged: cubit.setArchSize,
          onSubmitPhone: cubit.submitPhone,
          onRequestConsultation: cubit.requestConsultation,
        );
      default:
        final question = calculatorGraph[state.currentStepId];
        if (question == null) return const SizedBox.shrink();
        return CalculatorQuestionView(
          question: question,
          canGoBack: state.canGoBack,
          onBack: cubit.goBack,
          onAnswer: (option) => cubit.answer(question.id, option.value),
        );
    }
  }
}
