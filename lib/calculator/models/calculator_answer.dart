/// Accumulated answers, keyed by question id. Used both to drive graph
/// navigation (`CalculatorQuestion.next`) and to compute the final result.
typedef CalculatorAnswers = Map<String, String>;

/// One selectable option for a [CalculatorQuestion].
class QuestionOption {
  const QuestionOption(this.value, this.label);

  final String value;
  final String label;
}
