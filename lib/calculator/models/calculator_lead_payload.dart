import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_answer.dart';

/// Everything that must reach Telegram once the patient taps "Хочу
/// записатися на консультацію" (ТЗ §7). Only the final state is sent — "не
/// передавати історію всіх перемикань; лише остаточний стан."
///
/// There is no backend wired up yet: sending this over the Telegram Bot API
/// requires a server that holds the bot token (ТЗ §7.1 explicitly forbids
/// keeping that token in the frontend), which this Flutter Web project does
/// not have. [LeadSubmissionService] is the seam where that backend call
/// belongs once it exists.
class CalculatorLeadPayload {
  const CalculatorLeadPayload({
    required this.phone,
    required this.city,
    required this.answers,
    required this.clinicalSummary,
    required this.finalImplantSystem,
    required this.finalCrownOrConstruction,
    required this.eurAmount,
    required this.uahEquivalent,
    required this.entryPage,
    required this.utmParams,
    required this.consultationRequested,
  });

  final String phone;
  final ServiceCity city;
  final CalculatorAnswers answers;
  final String clinicalSummary;
  final String finalImplantSystem;
  final String finalCrownOrConstruction;
  final double eurAmount;
  final double uahEquivalent;
  final String entryPage;
  final Map<String, String> utmParams;
  final bool consultationRequested;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'city': city.label,
    'answers': answers,
    'clinicalSummary': clinicalSummary,
    'finalImplantSystem': finalImplantSystem,
    'finalCrownOrConstruction': finalCrownOrConstruction,
    'eurAmount': eurAmount,
    'uahEquivalent': uahEquivalent,
    'entryPage': entryPage,
    'utmParams': utmParams,
    'source': 'Сайт → калькулятор імплантації',
    'consultationRequested': consultationRequested,
  };
}
