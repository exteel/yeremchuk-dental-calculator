import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeremchuk_dental_calculator/calculator/cubit/implant_calculator_cubit.dart';
import 'package:yeremchuk_dental_calculator/calculator/cubit/implant_calculator_state.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/calculator_graph.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/services/calculator_analytics.dart';

class _NoopAnalytics implements CalculatorAnalytics {
  @override
  void logEvent(String name, Map<String, dynamic> params) {}
}

ImplantCalculatorCubit _buildCubit() =>
    ImplantCalculatorCubit(analytics: _NoopAnalytics());

void main() {
  group('ImplantCalculatorCubit', () {
    late ImplantCalculatorCubit cubit;

    setUp(() => cubit = _buildCubit());
    tearDown(() => cubit.close());

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'single tooth reaches a result with the amount hidden until the '
      'phone is submitted (ТЗ §6)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'already_removed');
      },
      verify: (c) {
        expect(c.state.currentStepId, CalculatorStep.result);
        expect(c.state.result, isNotNull);
        expect(c.state.result!.isIndividualOnly, isFalse);
        expect(c.state.phoneSubmitted, isFalse);
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'submitPhone reveals the result without touching the computed total',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'already_removed');
        final before = c.state.result!.eurAmount;
        c.submitPhone('0501112233');
        expect(c.state.result!.eurAmount, before);
      },
      verify: (c) {
        expect(c.state.phoneSubmitted, isTrue);
        expect(c.state.phone, '0501112233');
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'toggling the implant tier recomputes the total live',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'already_removed');
        final rational = c.state.result!.eurAmount;
        c.setPrimaryTier(2); // premium
        expect(c.state.result!.eurAmount, isNot(rational));
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'replacing an existing implant is a consultation-only dead end '
      '(ТЗ §5.3)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.chernivtsi)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'replace_implant_or_crown');
      },
      verify: (c) => expect(c.state.result!.isIndividualOnly, isTrue),
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'full jaw on one side reaches an arch result defaulting to All-on-6',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'full_jaw_one')
          ..answer('e1', 'no_teeth');
      },
      verify: (c) {
        expect(c.state.currentStepId, CalculatorStep.result);
        expect(c.state.archSize, 6);
        expect(c.state.result!.archFirstStageEur, greaterThan(0));
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'goBack returns to the previous step without losing answers',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..goBack();
      },
      verify: (c) {
        expect(c.state.currentStepId, 'q1');
        expect(c.state.answers['q1'], 'one_tooth');
      },
    );
  });
}
