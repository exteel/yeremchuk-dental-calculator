import 'package:yeremchuk_dental_calculator/calculator/models/calculator_answer.dart';

/// Special step ids that are not [CalculatorQuestion]s — handled directly by
/// `ImplantCalculatorScreen`/the cubit.
abstract class CalculatorStep {
  static const city = 'city';
  static const result = 'result';
}

/// One question: a screen with a single choice among [options]. [next]
/// computes the following step id from everything answered so far (ТЗ UX
/// §10 "не показувати нерелевантні питання").
class CalculatorQuestion {
  const CalculatorQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.next,
  });

  final String id;
  final String text;
  final List<QuestionOption> options;
  final String Function(CalculatorAnswers answers) next;

  static String toResult(CalculatorAnswers _) => CalculatorStep.result;
}

/// The branching graph from ТЗ §5, keyed by question id. Every leaf routes
/// to [CalculatorStep.result]; `scenario_resolver.dart` turns the full
/// answers map into pricing-engine inputs.
final Map<String, CalculatorQuestion> calculatorGraph = {
  // ---- §5.2: основне питання --------------------------------------------
  'q1': CalculatorQuestion(
    id: 'q1',
    text: 'Скільки зубів потрібно відновити?',
    options: const [
      QuestionOption('one_tooth', 'Один зуб'),
      QuestionOption('few_2_3', '2–3 зуби поруч'),
      QuestionOption('four_plus', '4 або більше зубів поруч'),
      QuestionOption('multiple_areas', 'Кілька зубів у різних ділянках'),
      QuestionOption(
        'full_jaw_one',
        'Більшість або всі зуби на одній щелепі',
      ),
      QuestionOption('full_jaw_both', 'Зуби на обох щелепах'),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: (a) => switch (a['q1']) {
      'one_tooth' => 'a1',
      'few_2_3' => 'b1',
      'four_plus' => 'c1',
      'multiple_areas' => 'd1',
      'full_jaw_one' => 'e1',
      'full_jaw_both' => 'f1',
      _ => 'g1',
    },
  ),

  // ---- §5.3: один зуб -----------------------------------------------------
  'a1': CalculatorQuestion(
    id: 'a1',
    text: 'Яка зараз ситуація із зубом?',
    options: const [
      QuestionOption('already_removed', 'Зуб уже видалений'),
      QuestionOption(
        'recommended_removal',
        'Зуб ще є, але його рекомендують видалити',
      ),
      QuestionOption(
        'unsure_preserve',
        'Не знаю, чи можна зберегти зуб',
      ),
      QuestionOption(
        'has_implant_needs_crown',
        'Імплант уже є, потрібна коронка',
      ),
      QuestionOption(
        'replace_implant_or_crown',
        'Заміна імпланта або коронки',
      ),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: CalculatorQuestion.toResult,
  ),

  // ---- §5.4: 2–3 зуби поруч ------------------------------------------------
  'b1': CalculatorQuestion(
    id: 'b1',
    text: 'Скільки зубів поруч потрібно відновити?',
    options: const [
      QuestionOption('two', 'Два'),
      QuestionOption('three', 'Три'),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: (a) => 'b2',
  ),
  'b2': CalculatorQuestion(
    id: 'b2',
    text: 'Яка зараз ситуація?',
    options: const [
      QuestionOption('all_removed', 'Усі вже видалені'),
      QuestionOption('some_removed', 'Частина видалена'),
      QuestionOption('still_present', 'Ще є'),
      QuestionOption('unsure_preserve', 'Не знаю, чи можна зберегти'),
      QuestionOption('has_implants', 'Імпланти вже встановлені'),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: CalculatorQuestion.toResult,
  ),

  // ---- §5.5: 4+ зубів поруч -------------------------------------------------
  'c1': CalculatorQuestion(
    id: 'c1',
    text: 'Скільки зубів поруч потрібно відновити?',
    options: const [
      QuestionOption('four', 'Чотири'),
      QuestionOption('five', "П'ять"),
      QuestionOption('six', 'Шість'),
      QuestionOption('seven_plus', 'Сім і більше'),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: (a) => a['c1'] == 'seven_plus' ? 'c2' : CalculatorStep.result,
  ),
  'c2': CalculatorQuestion(
    id: 'c2',
    text: 'Що розглядаєте для 7 і більше зубів поруч?',
    options: const [
      QuestionOption(
        'bridge_4',
        'Міст на 4 імплантах зі збереженням власних зубів',
      ),
      QuestionOption(
        'full_arch',
        'Заміна ряду незнімною конструкцією на 4/6/8 імплантах',
      ),
      QuestionOption('compare', 'Порівняти обидва варіанти'),
      QuestionOption('unknown', 'Потрібна рекомендація лікаря'),
    ],
    next: CalculatorQuestion.toResult,
  ),

  // ---- §5.6: зуби в різних ділянках -----------------------------------------
  'd1': CalculatorQuestion(
    id: 'd1',
    text: 'Скільки окремих зубів потрібно відновити?',
    options: const [
      QuestionOption('two', 'Два'),
      QuestionOption('three', 'Три'),
      QuestionOption('four_plus', 'Чотири і більше'),
      QuestionOption('mixed', 'Змішана ситуація'),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: CalculatorQuestion.toResult,
  ),

  // ---- §5.7: одна повна щелепа -----------------------------------------------
  'e1': CalculatorQuestion(
    id: 'e1',
    text: 'Яка зараз ситуація з щелепою?',
    options: const [
      QuestionOption('no_teeth', 'Зубів немає'),
      QuestionOption('mobile_teeth', 'Рухомі зуби'),
      QuestionOption('mostly_damaged', 'Більшість зруйновані'),
      QuestionOption('denture', 'Знімний протез'),
      QuestionOption(
        'existing_implant_construction',
        'Уже є конструкція на імплантах',
      ),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: CalculatorQuestion.toResult,
  ),

  // ---- §5.8: обидві щелепи -----------------------------------------------------
  'f1': CalculatorQuestion(
    id: 'f1',
    text: 'Яка зараз ситуація з обома щелепами?',
    options: const [
      QuestionOption('no_teeth', 'Зубів немає'),
      QuestionOption('mobile_or_damaged', 'Рухомі або зруйновані'),
      QuestionOption('one_side_empty', 'Одна щелепа без зубів'),
      QuestionOption('denture', 'Знімні протези'),
      QuestionOption(
        'existing_implant_construction',
        'Наявні конструкції на імплантах',
      ),
      QuestionOption('unknown', 'Не знаю'),
    ],
    next: CalculatorQuestion.toResult,
  ),

  // ---- §5.9: не знаю, що потрібно -----------------------------------------------
  'g1': CalculatorQuestion(
    id: 'g1',
    text: 'Що найкраще описує вашу ситуацію?',
    options: const [
      QuestionOption('missing_one', 'Відсутній один зуб'),
      QuestionOption('missing_several', 'Відсутні декілька зубів поруч'),
      QuestionOption(
        'most_teeth_bad',
        'Більшість зубів у поганому стані',
      ),
      QuestionOption('cant_determine', 'Не можу визначити'),
    ],
    next: (a) => switch (a['g1']) {
      'missing_one' => 'a1',
      'missing_several' => 'b1',
      'most_teeth_bad' => 'e1',
      _ => CalculatorStep.result,
    },
  ),
};
