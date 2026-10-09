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
      'existing implant + new crown: only the crown-tier toggle changes '
      'the total (regression — it used to be silently ignored)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'has_implant_needs_crown')
          ..answer('implant_system', 'premium');
        expect(c.state.result!.primaryTierLabel, isEmpty);
        expect(c.state.result!.secondaryTierLabel, 'Рівень коронки');
        final before = c.state.result!.eurAmount;
        c.setSecondaryTier(2); // premium crown
        expect(c.state.result!.eurAmount, isNot(before));
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'existing Neodent-group implant uses the standard superstructure '
      '(regression — it was always priced as Straumann)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'has_implant_needs_crown')
          ..answer('implant_system', 'standard');
        // SUPRA_STD 100 € + CROWN_OPT 500 € (default crown tier = optimal).
        expect(c.state.result!.eurAmount, 600);
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'unknown existing implant system goes to consultation (ТЗ §4.5)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'has_implant_needs_crown')
          ..answer('implant_system', 'unknown');
        expect(c.state.result!.isIndividualOnly, isTrue);
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'three adjacent teeth on existing implants count 2 superstructures '
      'and 3 crowns (regression — it was priced as one)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'few_2_3')
          ..answer('b1', 'three')
          ..answer('b2', 'has_implants')
          ..answer('implant_system', 'premium');
        // 2 × SUPRA_PREM 200 € + 3 × CROWN_OPT 500 €.
        expect(c.state.result!.eurAmount, 2 * 200 + 3 * 500);
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'going back and switching branch drops the abandoned branch '
      '(regression — the old answers won)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'already_removed')
          ..goBack() // result → a1
          ..goBack() // a1 → q1
          ..answer('q1', 'full_jaw_one')
          ..answer('e1', 'no_teeth');
        expect(c.state.answers.containsKey('a1'), isFalse);
        expect(c.state.result!.archFirstStageEur, greaterThan(0));
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      '7+ teeth with "міст на 4 імплантах" gives a 4-implant bridge, not '
      'All-on-6 (regression — the follow-up was ignored)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'four_plus')
          ..answer('c1', 'seven_plus')
          ..answer('c2', 'bridge_4');
        expect(c.state.result!.clinicalSummary, '4 імпланти + 7 коронок');
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'switching city reprices without re-answering',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'already_removed');
        expect(c.state.result!.eurAmount, 1480); // Straumann + opt, IF
        c.changeCity(ServiceCity.chernivtsi);
        expect(c.state.result!.eurAmount, 1280); // Straumann + opt, CV
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'temp crown adds abutment, temp unit and a second scan (ТЗ §4.3)',
      build: () => cubit,
      act: (c) {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'one_tooth')
          ..answer('a1', 'already_removed');
        expect(c.state.result!.tempCrownAvailable, isTrue);
        final before = c.state.result!;
        c.toggleTempCrown(true);
        expect(c.state.result!.eurAmount, before.eurAmount + 100);
        expect(
          c.state.result!.uahComponentAmount,
          before.uahComponentAmount + 2100 + 3400,
        );
      },
    );

    blocTest<ImplantCalculatorCubit, ImplantCalculatorState>(
      'progress bar is full once the request is sent (regression — it '
      'stopped at ~60-70% on the result screen)',
      build: () => cubit,
      act: (c) async {
        c
          ..selectCity(ServiceCity.ivanoFrankivsk)
          ..answer('q1', 'few_2_3')
          ..answer('b1', 'three');
        expect(c.state.progressFraction, lessThanOrEqualTo(0.7));
        c.answer('b2', 'all_removed');
        final atResult = c.state.progressFraction;
        c.submitPhone('0671234567');
        final revealed = c.state.progressFraction;
        await c.requestConsultation();
        expect(atResult, greaterThan(0.7));
        expect(revealed, greaterThan(atResult));
        expect(c.state.progressFraction, 1);
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
