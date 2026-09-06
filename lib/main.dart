import 'package:flutter/material.dart';
import 'package:yeremchuk_dental_calculator/calculator/screens/implant_calculator_screen.dart';
import 'package:yeremchuk_dental_calculator/theme/app_theme.dart';

void main() {
  runApp(const YeremchukDentalCalculatorApp());
}

/// The whole app is the implant cost calculator — no other pages.
class YeremchukDentalCalculatorApp extends StatelessWidget {
  const YeremchukDentalCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор імплантації — Yeremchuk Dental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ImplantCalculatorScreen(),
    );
  }
}
