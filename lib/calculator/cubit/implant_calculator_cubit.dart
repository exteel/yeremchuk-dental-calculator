import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yeremchuk_dental_calculator/calculator/cubit/implant_calculator_state.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/calculator_graph.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/pricing_engine.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/scenario_resolver.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_answer.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_lead_payload.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_result.dart';
import 'package:yeremchuk_dental_calculator/calculator/services/calculator_analytics.dart';
import 'package:yeremchuk_dental_calculator/calculator/services/lead_submission_service.dart';

/// State machine driving the calculator (ТЗ §5-§7). Walks [calculatorGraph]
/// question-by-question, then combines the answers ([resolveScenario]) with
/// the currently selected tiers to compute a [CalculatorResult] via
/// [PricingEngine] — recomputed on every tier/arch-size toggle, and hidden
/// from the payload/UI until [submitPhone] is called.
class ImplantCalculatorCubit extends Cubit<ImplantCalculatorState> {
  ImplantCalculatorCubit({
    required this.analytics,
    this.leadService = const StubLeadSubmissionService(),
    PricingEngine? engine,
    String entryPage = '',
    Map<String, String> utmParams = const {},
  }) : engine = engine ?? const PricingEngine(),
       entryPage = entryPage,
       utmParams = utmParams,
       super(ImplantCalculatorState.initial()) {
    analytics.logEvent(CalculatorAnalyticsEvent.opened, {'page': entryPage});
  }

  final PricingEngine engine;
  final CalculatorAnalytics analytics;
  final LeadSubmissionService leadService;
  final String entryPage;
  final Map<String, String> utmParams;

  void selectCity(ServiceCity city) {
    analytics.logEvent(CalculatorAnalyticsEvent.started, {
      'city': city.label,
    });
    emit(
      state.copyWith(
        city: city,
        currentStepId: 'q1',
        history: [...state.history, CalculatorStep.city],
      ),
    );
  }

  void answer(String questionId, String value) {
    // Only answers on the current path survive: going back and switching
    // branch must drop the abandoned branch, or resolveScenario (which
    // checks branches in a fixed order) would price the old one.
    final updatedAnswers = {
      for (final e in state.answers.entries)
        if (state.history.contains(e.key)) e.key: e.value,
      questionId: value,
    };
    analytics.logEvent(CalculatorAnalyticsEvent.questionAnswered, {
      'question': questionId,
      'value': value,
    });

    final question = calculatorGraph[questionId];
    final nextStepId = question?.next(updatedAnswers) ?? CalculatorStep.result;

    CalculatorResult? result;
    if (nextStepId == CalculatorStep.result) {
      result = _buildResult(updatedAnswers);
      analytics.logEvent(CalculatorAnalyticsEvent.resultReached, {
        'isIndividualOnly': result.isIndividualOnly,
        'isRoughEstimate': result.isRoughEstimate,
      });
    }

    // The phone is deliberately kept (the patient already gave it), but a
    // booking made for a previous scenario must not mark this one booked.
    emit(
      state.copyWith(
        currentStepId: nextStepId,
        history: [...state.history, state.currentStepId],
        answers: updatedAnswers,
        result: result ?? state.result,
        consultationRequested: false,
      ),
    );
  }

  void goBack() {
    if (!state.canGoBack) return;
    final history = [...state.history];
    final previous = history.removeLast();
    emit(state.copyWith(currentStepId: previous, history: history));
  }

  void setPrimaryTier(int index) {
    emit(state.copyWith(primaryTierIndex: index));
    _recompute();
  }

  void setSecondaryTier(int index) {
    emit(state.copyWith(secondaryTierIndex: index));
    _recompute();
  }

  void setArchSize(int size) {
    emit(state.copyWith(archSize: size));
    _recompute();
  }

  /// ТЗ §5.1 "Змінити місто" — reprices the same scenario for the other
  /// city without walking back through the questions.
  void changeCity(ServiceCity city) {
    emit(state.copyWith(city: city));
    _recompute();
  }

  // ignore: avoid_positional_boolean_parameters
  void toggleTempCrown(bool requested) {
    emit(state.copyWith(tempCrownRequested: requested));
    _recompute();
  }

  void _recompute() {
    if (state.currentStepId != CalculatorStep.result) return;
    emit(state.copyWith(result: _buildResult(state.answers)));
  }

  CalculatorResult _buildResult(CalculatorAnswers answers) {
    final city = state.city ?? ServiceCity.ivanoFrankivsk;
    final spec = resolveScenario(answers);
    final notices = resolveNotices(answers);
    final rough = isRoughEstimateOnly(answers);

    switch (spec.kind) {
      case ScenarioKind.individual:
        return CalculatorResult(
          kind: ResultKind.individual,
          clinicalSummary: '',
          eurAmount: 0,
          uahComponentAmount: 0,
          uahEquivalentTotal: 0,
          breakdown: const [],
          combos: const [],
          primaryTierLabel: '',
          secondaryTierLabel: '',
          isIndividualOnly: true,
          individualMessage: spec.individualMessage,
          individualCta: spec.individualCta,
        );

      case ScenarioKind.existingImplant:
        final crown = ServiceCatalog.crownTiers[state.secondaryTierIndex];
        final r = engine.existingImplantTotal(
          city: city,
          group: spec.implantGroup,
          crown: crown,
          implantCount: spec.implantCount,
          crownUnits: spec.crownUnits,
          immediatelyPermanent: !state.tempCrownRequested,
        );
        return _withContext(r, spec, city, notices, rough);

      case ScenarioKind.unit:
        final implant =
            ServiceCatalog.singleToothImplantTiers[state.primaryTierIndex];
        final crown = ServiceCatalog.crownTiers[state.secondaryTierIndex];
        final tempCrown = spec.tempCrownEligible && state.tempCrownRequested;
        final combos = engine.unitCombos(
          city: city,
          implantTiers: ServiceCatalog.singleToothImplantTiers,
          implantCount: spec.implantCount,
          crownUnits: spec.crownUnits,
          currentImplantIndex: state.primaryTierIndex,
          currentCrownIndex: state.secondaryTierIndex,
          tempCrown: tempCrown,
        );
        final r = engine.unitScenario(
          city: city,
          implant: implant,
          crown: crown,
          implantCount: spec.implantCount,
          crownUnits: spec.crownUnits,
          tempCrown: tempCrown,
          combos: combos,
        );
        return _withContext(r, spec, city, notices, rough);

      case ScenarioKind.arch:
        final implant =
            ServiceCatalog.fullArchImplantTiers[state.primaryTierIndex];
        final archFinal = ServiceCatalog.archFinalTiers[state.secondaryTierIndex];
        final combos = engine.archSizeCombos(
          city: city,
          implant: implant,
          archFinal: archFinal,
          bothJaws: spec.bothJaws,
          currentSize: state.archSize,
        );
        final r = engine.allOnScenario(
          city: city,
          implant: implant,
          archFinal: archFinal,
          implantsPerJaw: state.archSize,
          bothJaws: spec.bothJaws,
          combos: combos,
        );
        return _withContext(r, spec, city, notices, rough);
    }
  }

  CalculatorResult _withContext(
    CalculatorResult r,
    ScenarioSpec spec,
    ServiceCity city,
    List<String> notices,
    bool rough,
  ) {
    final isArch = spec.kind == ScenarioKind.arch;
    return CalculatorResult(
      kind: r.kind,
      clinicalSummary: r.clinicalSummary,
      eurAmount: r.eurAmount,
      uahComponentAmount: r.uahComponentAmount,
      uahEquivalentTotal: r.uahEquivalentTotal,
      breakdown: r.breakdown,
      combos: r.combos,
      primaryTierLabel: r.primaryTierLabel,
      secondaryTierLabel: r.secondaryTierLabel,
      archFirstStageEur: r.archFirstStageEur,
      archFirstStageUah: r.archFirstStageUah,
      archFullEur: r.archFullEur,
      archFullUah: r.archFullUah,
      noticeTexts: notices,
      tempCrownAvailable: spec.tempCrownEligible,
      sedationEstimate: engine.estimateSedationRange(
        city: city,
        implantCount: isArch ? state.archSize : spec.implantCount,
        fullJaw: isArch,
        bothJaws: spec.bothJaws,
      ),
      isRoughEstimate: rough,
    );
  }

  /// ТЗ §6: reveals the amount — no SMS confirmation.
  void submitPhone(String phone) {
    analytics.logEvent(CalculatorAnalyticsEvent.phoneSubmitted, {});
    emit(state.copyWith(phone: phone, phoneSubmitted: true));
  }

  /// ТЗ §6.3/§7 — "Хочу записатися на консультацію".
  Future<bool> requestConsultation() async {
    if (state.result == null || state.city == null) return false;
    emit(state.copyWith(consultationSubmitting: true));

    final result = state.result!;
    // Consultation-only results never showed tier choices, so the default
    // tier indices would misreport what the patient picked.
    final individual = result.isIndividualOnly;
    final payload = CalculatorLeadPayload(
      phone: state.phone,
      city: state.city!,
      answers: state.answers,
      clinicalSummary: individual
          ? 'Лише консультація: ${result.individualMessage ?? ''}'
          : result.clinicalSummary,
      finalImplantSystem: individual ? '—' : _currentImplantLabel(result),
      finalCrownOrConstruction: individual
          ? '—'
          : _currentSecondaryLabel(result),
      eurAmount: result.kind == ResultKind.fullArch
          ? result.archFullEur
          : result.eurAmount,
      uahEquivalent: result.uahEquivalentTotal,
      entryPage: entryPage,
      utmParams: utmParams,
      consultationRequested: true,
    );

    final success = await leadService.submit(payload);
    analytics.logEvent(CalculatorAnalyticsEvent.bookingClicked, {
      'success': success,
    });
    emit(
      state.copyWith(
        consultationSubmitting: false,
        consultationRequested: success,
      ),
    );
    return success;
  }

  String _currentImplantLabel(CalculatorResult result) {
    final system = state.answers['implant_system'];
    if (system != null) {
      return system == 'premium'
          ? 'Наявний імплант (Straumann-група)'
          : 'Наявний імплант (Neodent-група)';
    }
    if (result.kind == ResultKind.fullArch) {
      return ServiceCatalog.fullArchImplantTiers[state.primaryTierIndex]
          .displayName;
    }
    return ServiceCatalog.singleToothImplantTiers[state.primaryTierIndex]
        .displayName;
  }

  String _currentSecondaryLabel(CalculatorResult result) {
    if (result.kind == ResultKind.fullArch) {
      return ServiceCatalog.archFinalTiers[state.secondaryTierIndex]
          .displayName;
    }
    return ServiceCatalog.crownTiers[state.secondaryTierIndex].displayName;
  }

  /// Best-effort abandonment signal for analytics.
  void logAbandonedIfIncomplete() {
    if (state.consultationRequested) return;
    analytics.logEvent(CalculatorAnalyticsEvent.abandoned, {
      'step': state.currentStepId,
    });
  }
}

