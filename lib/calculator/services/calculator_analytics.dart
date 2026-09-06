import 'package:flutter/foundation.dart';

/// Event names for ТЗ §16. Kept as constants so call sites can't typo them.
abstract class CalculatorAnalyticsEvent {
  static const opened = 'calculator_opened';
  static const started = 'calculator_started';
  static const questionAnswered = 'calculator_question_answered';
  static const branchSelected = 'calculator_branch_selected';
  static const resultReached = 'calculator_result_reached';
  static const phoneSubmitted = 'calculator_phone_submitted';
  static const bookingClicked = 'calculator_booking_clicked';
  static const abandoned = 'calculator_abandoned';
}

/// Analytics sink for the calculator (ТЗ §16). No analytics SDK is wired
/// into this project yet — swap [DebugPrintCalculatorAnalytics] for a real
/// implementation (Firebase/Amplitude/GTM/etc.) without touching the cubit.
abstract class CalculatorAnalytics {
  void logEvent(String name, Map<String, dynamic> params);
}

class DebugPrintCalculatorAnalytics implements CalculatorAnalytics {
  const DebugPrintCalculatorAnalytics();

  @override
  void logEvent(String name, Map<String, dynamic> params) {
    if (kDebugMode) {
      debugPrint('[calculator analytics] $name $params');
    }
  }
}
