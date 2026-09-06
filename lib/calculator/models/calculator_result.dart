import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';

/// One priced line in the "деталізація" breakdown (ТЗ §10: "у деталізації
/// відділяти ціну імпланта зі встановленням від повного відновлення").
class BreakdownLine {
  const BreakdownLine(this.label, this.money);

  final String label;
  final Money money;
}

/// One of up to 3 comparison cards for a two-dimensional tier choice
/// (implant × crown, or implant × arch construction) — ТЗ §6.1/§6.2 "Три
/// картки: поточна, найближча дешевша, найближча дорожча".
class TierCombo {
  const TierCombo({
    required this.primaryTierIndex,
    required this.secondaryTierIndex,
    required this.label,
    required this.eurTotal,
    required this.uahEquivalentTotal,
    required this.isCurrent,
  });

  final int primaryTierIndex;
  final int secondaryTierIndex;
  final String label;
  final double eurTotal;
  final double uahEquivalentTotal;
  final bool isCurrent;
}

enum ResultKind { singleOrBridge, fullArch, individual }

/// Full computed outcome shown on the result screen (ТЗ §6).
class CalculatorResult {
  const CalculatorResult({
    required this.kind,
    required this.clinicalSummary,
    required this.eurAmount,
    required this.uahComponentAmount,
    required this.uahEquivalentTotal,
    required this.breakdown,
    required this.combos,
    required this.primaryTierLabel,
    required this.secondaryTierLabel,
    this.archFirstStageEur = 0,
    this.archFirstStageUah = 0,
    this.archFullEur = 0,
    this.archFullUah = 0,
    this.noticeTexts = const [],
    this.isRoughEstimate = false,
    this.isIndividualOnly = false,
    this.individualMessage,
    this.individualCta,
  });

  final ResultKind kind;

  /// "Клінічна схема" (ТЗ §6.1) — e.g. "1 імплант + 1 коронка" — does not
  /// change when the patient toggles implant/crown tier.
  final String clinicalSummary;

  final double eurAmount;
  final double uahComponentAmount;
  final double uahEquivalentTotal;
  final List<BreakdownLine> breakdown;
  final List<TierCombo> combos;
  final String primaryTierLabel;
  final String secondaryTierLabel;

  /// All-on-4/6/8 only (ТЗ §6.2): first-stage (temporary) figure is the
  /// headline number; full treatment cost is shown below it.
  final double archFirstStageEur;
  final double archFirstStageUah;
  final double archFullEur;
  final double archFullUah;

  /// ТЗ §10 informational notices tied to specific answers.
  final List<String> noticeTexts;

  /// ТЗ §5.9 — data is genuinely insufficient; frame the combo cards as
  /// "3 приблизні рівні" rather than a firm quote.
  final bool isRoughEstimate;

  /// ТЗ §5.3/§5.9 dead-ends: no priced result, just a message + CTA into
  /// the consultation booking.
  final bool isIndividualOnly;
  final String? individualMessage;
  final String? individualCta;

  static const warningText =
      'Це попередній розрахунок, а не остаточний план лікування. Точну '
      'кількість імплантів та остаточну вартість визначає лікар після '
      'огляду і КТ.';
}
