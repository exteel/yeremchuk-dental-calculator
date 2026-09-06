import 'package:flutter_test/flutter_test.dart';
import 'package:yeremchuk_dental_calculator/calculator/screens/implant_calculator_screen.dart';

import '../helpers/helpers.dart';

void main() {
  group('ImplantCalculatorScreen', () {
    testWidgets('renders the city step first', (tester) async {
      await tester.pumpApp(const ImplantCalculatorScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Розрахуйте орієнтовну вартість імплантації'),
        findsOneWidget,
      );
      expect(find.text('Івано-Франківськ'), findsOneWidget);
      expect(find.text('Чернівці'), findsOneWidget);
    });

    testWidgets('picking a city shows the first question', (tester) async {
      await tester.pumpApp(const ImplantCalculatorScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Івано-Франківськ'));
      await tester.pumpAndSettle();

      expect(find.text('Скільки зубів потрібно відновити?'), findsOneWidget);
    });

    testWidgets('the result screen still offers a way back (ТЗ UX §10 — '
        'regression: it used to have no back button at all)', (tester) async {
      await tester.pumpApp(const ImplantCalculatorScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Івано-Франківськ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Один зуб'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Зуб уже видалений'));
      await tester.pumpAndSettle();

      expect(find.text('Назад'), findsOneWidget);
    });
  });
}
