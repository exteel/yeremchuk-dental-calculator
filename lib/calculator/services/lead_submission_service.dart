import 'package:flutter/foundation.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_lead_payload.dart';

/// Sends a completed calculator lead to Telegram (ТЗ §7). No backend exists
/// yet to hold the bot token, so [StubLeadSubmissionService] just logs and
/// simulates success — swap in a real HTTP call to that backend later
/// without touching the cubit or UI.
abstract class LeadSubmissionService {
  Future<bool> submit(CalculatorLeadPayload payload);
}

class StubLeadSubmissionService implements LeadSubmissionService {
  const StubLeadSubmissionService();

  @override
  Future<bool> submit(CalculatorLeadPayload payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (kDebugMode) {
      debugPrint('[calculator lead - STUB, not sent anywhere] ${payload.toJson()}');
    }
    return true;
  }
}
