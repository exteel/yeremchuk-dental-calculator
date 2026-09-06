import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_answer.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_result.dart';

class ImplantCalculatorState {
  const ImplantCalculatorState({
    required this.currentStepId,
    required this.history,
    required this.answers,
    this.city,
    this.primaryTierIndex = 1,
    this.secondaryTierIndex = 1,
    this.archSize = 6,
    this.tempCrownRequested = false,
    this.result,
    this.phone = '',
    this.phoneSubmitted = false,
    this.consultationSubmitting = false,
    this.consultationRequested = false,
  });

  factory ImplantCalculatorState.initial() => const ImplantCalculatorState(
    currentStepId: 'city',
    history: [],
    answers: {},
  );

  final String currentStepId;
  final List<String> history;
  final CalculatorAnswers answers;
  final ServiceCity? city;

  /// Independently selectable tiers (ТЗ §4.2/§6): index into
  /// implant-system tiers and crown/construction tiers, 0=rational,
  /// 1=optimal, 2=premium.
  final int primaryTierIndex;
  final int secondaryTierIndex;

  /// Full-jaw only: which of 4/6/8 is currently shown as the headline
  /// figure (ТЗ §6.2 "Три картки 4/6/8").
  final int archSize;

  final bool tempCrownRequested;
  final CalculatorResult? result;

  /// ТЗ §6: sum stays hidden until a phone number is submitted — no SMS.
  final String phone;
  final bool phoneSubmitted;

  final bool consultationSubmitting;
  final bool consultationRequested;

  bool get canGoBack => history.isNotEmpty;

  /// Loose progress estimate — ТЗ UX §10 forbids a fixed "крок X із Y"
  /// label since question count varies, so this only ever backs a visual
  /// bar, never printed text.
  double get progressFraction =>
      (history.length / 6).clamp(0.05, 1).toDouble();

  ImplantCalculatorState copyWith({
    String? currentStepId,
    List<String>? history,
    CalculatorAnswers? answers,
    ServiceCity? city,
    int? primaryTierIndex,
    int? secondaryTierIndex,
    int? archSize,
    bool? tempCrownRequested,
    CalculatorResult? result,
    String? phone,
    bool? phoneSubmitted,
    bool? consultationSubmitting,
    bool? consultationRequested,
  }) {
    return ImplantCalculatorState(
      currentStepId: currentStepId ?? this.currentStepId,
      history: history ?? this.history,
      answers: answers ?? this.answers,
      city: city ?? this.city,
      primaryTierIndex: primaryTierIndex ?? this.primaryTierIndex,
      secondaryTierIndex: secondaryTierIndex ?? this.secondaryTierIndex,
      archSize: archSize ?? this.archSize,
      tempCrownRequested: tempCrownRequested ?? this.tempCrownRequested,
      result: result ?? this.result,
      phone: phone ?? this.phone,
      phoneSubmitted: phoneSubmitted ?? this.phoneSubmitted,
      consultationSubmitting:
          consultationSubmitting ?? this.consultationSubmitting,
      consultationRequested:
          consultationRequested ?? this.consultationRequested,
    );
  }
}
