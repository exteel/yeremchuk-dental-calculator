import 'package:yeremchuk_dental_calculator/calculator/models/calculator_answer.dart';

/// What kind of pricing-engine call the resolved answers need.
enum ScenarioKind { unit, arch, existingImplant, individual }

/// Pure translation of the accumulated [CalculatorAnswers] (ТЗ §5) into
/// parameters the pricing engine understands — kept separate from
/// `pricing_engine.dart` so the branching logic and the arithmetic can be
/// read (and tested) independently.
class ScenarioSpec {
  const ScenarioSpec.unit({
    required this.implantCount,
    required this.crownUnits,
    this.tempCrownEligible = true,
  }) : kind = ScenarioKind.unit,
       archImplantsPerJaw = 0,
       bothJaws = false,
       immediatelyPermanent = true,
       individualMessage = null,
       individualCta = null;

  const ScenarioSpec.arch({
    required this.archImplantsPerJaw,
    this.bothJaws = false,
  }) : kind = ScenarioKind.arch,
       implantCount = 0,
       crownUnits = 0,
       tempCrownEligible = false,
       immediatelyPermanent = true,
       individualMessage = null,
       individualCta = null;

  const ScenarioSpec.existingImplant({required this.immediatelyPermanent})
    : kind = ScenarioKind.existingImplant,
      implantCount = 1,
      crownUnits = 1,
      tempCrownEligible = false,
      archImplantsPerJaw = 0,
      bothJaws = false,
      individualMessage = null,
      individualCta = null;

  const ScenarioSpec.individual({
    required String message,
    required String cta,
  }) : kind = ScenarioKind.individual,
       implantCount = 0,
       crownUnits = 0,
       tempCrownEligible = false,
       archImplantsPerJaw = 0,
       bothJaws = false,
       immediatelyPermanent = true,
       individualMessage = message,
       individualCta = cta;

  final ScenarioKind kind;
  final int implantCount;
  final int crownUnits;
  final bool tempCrownEligible;
  final int archImplantsPerJaw;
  final bool bothJaws;
  final bool immediatelyPermanent;
  final String? individualMessage;
  final String? individualCta;
}

/// ТЗ §4.4 — sequential adjacent teeth to (implants, crown units).
(int implants, int units) adjacentBridgeCounts(int adjacentTeeth) =>
    switch (adjacentTeeth) {
      1 => (1, 1),
      2 => (2, 2),
      3 => (2, 3),
      4 => (2, 4),
      5 => (3, 5),
      6 => (3, 6),
      _ => (4, adjacentTeeth),
    };

const _replaceMessage =
    'Заміна наявного імпланта або коронки потребує індивідуальної оцінки '
    'стану кістки та конструкції.';
const _replaceCta = 'Записатися на консультацію';

const _existingConstructionMessage =
    'Оцінка наявної конструкції на імплантах потребує огляду та КТ — '
    'точну вартість заміни попередньо визначити неможливо.';
const _existingConstructionCta = 'Записатися на консультацію';

ScenarioSpec resolveScenario(CalculatorAnswers a) {
  // ---- Branch A: один зуб (§5.3) ----
  if (a.containsKey('a1')) {
    return switch (a['a1']) {
      'replace_implant_or_crown' => const ScenarioSpec.individual(
        message: _replaceMessage,
        cta: _replaceCta,
      ),
      'has_implant_needs_crown' => const ScenarioSpec.existingImplant(
        immediatelyPermanent: true,
      ),
      _ => const ScenarioSpec.unit(implantCount: 1, crownUnits: 1),
    };
  }

  // ---- Branch B: 2–3 зуби поруч (§5.4) ----
  if (a.containsKey('b1')) {
    if (a['b2'] == 'has_implants') {
      return const ScenarioSpec.existingImplant(immediatelyPermanent: true);
    }
    final count = switch (a['b1']) { 'two' => 2, 'three' => 3, _ => 3 };
    final (implants, units) = adjacentBridgeCounts(count);
    return ScenarioSpec.unit(implantCount: implants, crownUnits: units);
  }

  // ---- Branch C: 4+ зубів поруч (§5.5) ----
  if (a.containsKey('c1')) {
    final count = switch (a['c1']) {
      'four' => 4,
      'five' => 5,
      'six' => 6,
      'seven_plus' => 7,
      _ => 6,
    };
    if (count >= 7) {
      // ТЗ §5.5: for 7+ compare a segmental bridge against a full-arch
      // replacement — the full-arch path is the clinically dominant one,
      // so the calculator defaults there and the result screen notes the
      // bridge alternative for the doctor to weigh in on.
      return const ScenarioSpec.arch(archImplantsPerJaw: 6);
    }
    final (implants, units) = adjacentBridgeCounts(count);
    return ScenarioSpec.unit(implantCount: implants, crownUnits: units);
  }

  // ---- Branch D: зуби в різних ділянках (§5.6) ----
  if (a.containsKey('d1')) {
    final count = switch (a['d1']) {
      'two' => 2,
      'three' => 3,
      'four_plus' => 4,
      _ => 2,
    };
    // Separate areas → one implant + one crown per tooth, no bridge saving.
    return ScenarioSpec.unit(
      implantCount: count,
      crownUnits: count,
      tempCrownEligible: false,
    );
  }

  // ---- Branch E: одна повна щелепа (§5.7) ----
  if (a.containsKey('e1')) {
    if (a['e1'] == 'existing_implant_construction') {
      return const ScenarioSpec.individual(
        message: _existingConstructionMessage,
        cta: _existingConstructionCta,
      );
    }
    return const ScenarioSpec.arch(archImplantsPerJaw: 6);
  }

  // ---- Branch F: обидві щелепи (§5.8) ----
  if (a.containsKey('f1')) {
    if (a['f1'] == 'existing_implant_construction') {
      return const ScenarioSpec.individual(
        message: _existingConstructionMessage,
        cta: _existingConstructionCta,
      );
    }
    return const ScenarioSpec.arch(archImplantsPerJaw: 6, bothJaws: true);
  }

  // ---- Branch G: не знаю (§5.9), unresolved fallback ----
  return const ScenarioSpec.unit(implantCount: 1, crownUnits: 1);
}

/// ТЗ §10 informational notices tied to specific answers — never priced
/// automatically, just context shown alongside the result.
List<String> resolveNotices(CalculatorAnswers a) {
  final notes = <String>[];
  if (a['a1'] == 'recommended_removal' || a['b2'] == 'still_present') {
    notes.add(
      'Видалення зуба(ів) не входить у суму автоматично — додається окремо '
      'за показаннями лікаря.',
    );
  }
  if (a['a1'] == 'unsure_preserve' ||
      a['a1'] == 'unknown' ||
      a['b2'] == 'unsure_preserve' ||
      a['d1'] == 'mixed') {
    notes.add(
      'Остаточне рішення про збереження власних зубів визначає лікар після '
      'огляду і КТ — нижче показано орієнтовні рівні.',
    );
  }
  if (a['c1'] == 'seven_plus') {
    notes.add(
      'Для 7 і більше зубів поруч варто порівняти сегментний міст і повну '
      'заміну ряду на консультації — нижче показано варіант повної щелепи.',
    );
  }
  return notes;
}

/// True when the current answers are genuinely unresolved and the "3
/// приблизні рівні" fallback framing (§5.9) applies, rather than a firm
/// scenario.
bool isRoughEstimateOnly(CalculatorAnswers a) =>
    a['a1'] == 'unsure_preserve' ||
    a['a1'] == 'unknown' ||
    a['b2'] == 'unsure_preserve' ||
    a['b1'] == 'unknown' ||
    a['c1'] == 'unknown' ||
    a['d1'] == 'mixed' ||
    a['d1'] == 'unknown' ||
    a['e1'] == 'unknown' ||
    a['f1'] == 'unknown' ||
    !(a.containsKey('a1') ||
        a.containsKey('b1') ||
        a.containsKey('c1') ||
        a.containsKey('d1') ||
        a.containsKey('e1') ||
        a.containsKey('f1'));
