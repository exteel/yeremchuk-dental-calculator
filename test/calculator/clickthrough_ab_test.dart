// Real-UI click-through for branches A (q1 "Один зуб") and B (q1 "2–3 зуби
// поруч"): every option of a1, b1 x b2, and implant_system, ending in the
// result screen, phone gate and booking CTA.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/calculator_graph.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/scenario_resolver.dart';
import 'package:yeremchuk_dental_calculator/calculator/screens/implant_calculator_screen.dart';

import '../helpers/helpers.dart';

const _phone = '0671234567';
const _roughBanner = 'Даних поки недостатньо для точного сценарію';
const _gateTitle = 'Ваш персональний розрахунок готовий';
const _showBtn = 'Показати розрахунок';
const _bookBtn = 'Хочу записатися на консультацію';
const _thanks = 'Дякуємо!';
const _cityIf = 'Івано-Франківськ';
const _cityCv = 'Чернівці';


int _clicks = 0;
int _leaves = 0;

String _optionLabel(String qid, String value) =>
    calculatorGraph[qid]!.options.firstWhere((o) => o.value == value).label;

/// Taps a widget found by text, scrolling it into view first.
Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget, reason: 'tap target "$text"');
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  _clicks++;
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  _clicks++;
}

Future<void> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpApp(const ImplantCalculatorScreen());
  await tester.pumpAndSettle();
}

Future<void> _startAt(WidgetTester tester, String city) async {
  await _setUp(tester);
  await _tapText(tester, city);
  expect(find.text(calculatorGraph['q1']!.text), findsOneWidget);
}

/// Answers a chain of (questionId, value) pairs, asserting that each
/// question screen is the expected one before tapping its option.
Future<void> _answer(
  WidgetTester tester,
  List<(String, String)> path,
) async {
  for (final (qid, value) in path) {
    expect(
      find.text(calculatorGraph[qid]!.text),
      findsOneWidget,
      reason: 'question $qid should be on screen',
    );
    await _tapText(tester, _optionLabel(qid, value));
  }
}

bool _buttonEnabled(WidgetTester tester, String label) {
  final btn = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, label),
  );
  return btn.onPressed != null;
}

Future<void> _enterPhone(WidgetTester tester) async {
  final field = find.byType(TextField);
  expect(field, findsOneWidget);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, _phone);
  await tester.pumpAndSettle();
  _clicks++;
}

Future<void> _tickConsent(WidgetTester tester) async {
  await _tapFinder(tester, find.textContaining('Погоджуюсь на обробку'));
}

/// Taps a booking CTA and lets the ~600 ms stub lead service finish.
Future<void> _book(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(ElevatedButton, label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  _clicks++;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  expect(find.textContaining(_thanks), findsOneWidget);
}

/// Priced result: gate, no sum, reveal, sum, booking.
Future<void> _completePriced(
  WidgetTester tester, {
  required String summary,
  required List<(String, String)> answersForNotices,
}) async {
  expect(find.text(summary), findsOneWidget, reason: 'clinical summary');
  expect(find.text(_gateTitle), findsOneWidget);
  expect(find.textContaining('€'), findsNothing,
      reason: 'no sum before the phone is submitted');
  expect(find.textContaining('за курсом НБУ'), findsNothing);
  expect(find.text(_bookBtn), findsNothing);

  final answers = {for (final (k, v) in answersForNotices) k: v};
  expect(
    find.textContaining(_roughBanner),
    isRoughEstimateOnly(answers) ? findsOneWidget : findsNothing,
    reason: 'rough estimate banner',
  );

  // Gate button must stay disabled until phone AND consent are present.
  expect(_buttonEnabled(tester, _showBtn), isFalse);
  await _enterPhone(tester);
  expect(_buttonEnabled(tester, _showBtn), isFalse,
      reason: 'phone alone is not enough');
  await _tickConsent(tester);
  expect(_buttonEnabled(tester, _showBtn), isTrue);
  expect(find.textContaining('€'), findsNothing);

  await _tapText(tester, _showBtn);
  expect(find.text(_gateTitle), findsNothing);
  expect(find.textContaining('€'), findsWidgets);
  expect(find.textContaining('≈'), findsOneWidget);
  expect(find.textContaining('за курсом НБУ'), findsOneWidget);
  expect(find.text(summary), findsOneWidget);
  for (final note in resolveNotices(answers)) {
    expect(find.text(note), findsOneWidget, reason: 'notice: $note');
  }

  await _book(tester, _bookBtn);
}

/// Consultation-only result: message, phone, consent, CTA.
Future<void> _completeIndividual(
  WidgetTester tester, {
  required String messageStart,
}) async {
  expect(find.textContaining(messageStart), findsOneWidget);
  expect(find.text(_gateTitle), findsNothing);
  expect(find.textContaining('€'), findsNothing);
  expect(find.byType(TextField), findsOneWidget);
  const cta = 'Записатися на консультацію';
  expect(_buttonEnabled(tester, cta), isFalse);
  await _enterPhone(tester);
  expect(_buttonEnabled(tester, cta), isFalse,
      reason: 'phone alone is not enough');
  await _tickConsent(tester);
  expect(_buttonEnabled(tester, cta), isTrue);
  await _book(tester, cta);
  expect(find.textContaining('€'), findsNothing);
}

// ---- expectations --------------------------------------------------------

const _msgReplace = 'Заміна наявного імпланта або коронки';
const _msgUnknownSystem = 'Щоб порахувати коронку на наявний імплант';

class _Leaf {
  const _Leaf(this.path, {this.summary, this.individualStart});
  final List<(String, String)> path;
  final String? summary; // priced
  final String? individualStart; // consultation-only
  String get name => path.map((p) => '${p.$1}=${p.$2}').join(' > ');
}

const _systems = ['standard', 'premium', 'unknown'];

List<_Leaf> _branchALeaves() {
  final leaves = <_Leaf>[];
  const base = [('q1', 'one_tooth')];
  for (final v in const [
    'already_removed',
    'recommended_removal',
    'unsure_preserve',
    'unknown',
  ]) {
    leaves.add(_Leaf([...base, ('a1', v)], summary: '1 імплант + 1 коронка'));
  }
  leaves.add(
    _Leaf(
      [...base, ('a1', 'replace_implant_or_crown')],
      individualStart: _msgReplace,
    ),
  );
  for (final s in _systems) {
    final path = [
      ...base,
      ('a1', 'has_implant_needs_crown'),
      ('implant_system', s),
    ];
    leaves.add(
      s == 'unknown'
          ? _Leaf(path, individualStart: _msgUnknownSystem)
          : _Leaf(path, summary: 'Постійна коронка на наявний імплант'),
    );
  }
  return leaves;
}

List<_Leaf> _branchBLeaves() {
  final leaves = <_Leaf>[];
  // b1 value -> number of teeth the resolver prices (unknown -> 3).
  const teeth = {'two': 2, 'three': 3, 'unknown': 3};
  const unitSummary = {
    2: '2 імпланти + 2 коронки',
    3: '2 імпланти + 3 коронки',
  };
  const existingSummary = {
    2: 'Постійна 2 коронки на 2 наявних імплантах',
    3: 'Постійна 3 коронки на 2 наявних імплантах',
  };
  for (final b1 in calculatorGraph['b1']!.options.map((o) => o.value)) {
    final n = teeth[b1]!;
    // Cross-check the hand-written literals against the ТЗ §4.4 table.
    final (implants, units) = adjacentBridgeCounts(n);
    assert(implants == 2 && units == n, 'table drifted for $n teeth');
    for (final b2 in calculatorGraph['b2']!.options.map((o) => o.value)) {
      final base = [('q1', 'few_2_3'), ('b1', b1), ('b2', b2)];
      if (b2 == 'has_implants') {
        for (final s in _systems) {
          final path = [...base, ('implant_system', s)];
          leaves.add(
            s == 'unknown'
                ? _Leaf(path, individualStart: _msgUnknownSystem)
                : _Leaf(path, summary: existingSummary[n]),
          );
        }
      } else {
        leaves.add(_Leaf(base, summary: unitSummary[n]));
      }
    }
  }
  return leaves;
}

void _defineLeafTests(String group, List<_Leaf> leaves) {
  for (final city in const [_cityIf, _cityCv]) {
    // Both cities are exercised on every leaf for branch A (cheap), and for
    // branch B on Івано-Франківськ plus a Чернівці pass below.
    if (city == _cityCv && group == 'B') continue;
    for (final leaf in leaves) {
      testWidgets('$group [$city] ${leaf.name}', (tester) async {
        await _startAt(tester, city);
        await _answer(tester, leaf.path);
        // After the last answer we must be on the result screen.
        expect(find.text('Назад'), findsOneWidget);
        _leaves++;
        final answers = [for (final (q, v) in leaf.path) (q, v)];
        if (leaf.summary != null) {
          await _completePriced(
            tester,
            summary: leaf.summary!,
            answersForNotices: answers,
          );
        } else {
          await _completeIndividual(
            tester,
            messageStart: leaf.individualStart!,
          );
        }
      });
    }
  }
}

void main() {
  tearDownAll(() {
    // ignore: avoid_print
    print('CLICKTHROUGH A/B: leaves=$_leaves clicks/inputs=$_clicks');
  });

  group('Branch A: Один зуб', () {
    _defineLeafTests('A', _branchALeaves());
  });

  group('Branch B: 2–3 зуби поруч', () {
    _defineLeafTests('B', _branchBLeaves());

    // Чернівці pass over the full B table for a few representative leaves
    // of every kind (priced / existing implant / consultation-only).
    for (final leaf in _branchBLeaves().where(
      (l) =>
          l.path.length >= 3 &&
          (l.path[2].$2 == 'all_removed' ||
              l.path[2].$2 == 'has_implants'),
    )) {
      testWidgets('B [$_cityCv] ${leaf.name}', (tester) async {
        await _startAt(tester, _cityCv);
        await _answer(tester, leaf.path);
        _leaves++;
        if (leaf.summary != null) {
          await _completePriced(
            tester,
            summary: leaf.summary!,
            answersForNotices: leaf.path,
          );
        } else {
          await _completeIndividual(
            tester,
            messageStart: leaf.individualStart!,
          );
        }
      });
    }
  });

  group('Back navigation', () {
    Future<void> backTo(WidgetTester tester, String questionText) async {
      await _tapText(tester, 'Назад');
      expect(find.text(questionText), findsOneWidget,
          reason: 'after Назад expected "$questionText"');
    }

    String q(String id) => calculatorGraph[id]!.text;
    const cityTitle = 'Розрахуйте орієнтовну вартість імплантації';

    testWidgets('A: result -> implant_system -> a1 -> q1 -> city', (
      tester,
    ) async {
      await _startAt(tester, _cityIf);
      await _answer(tester, const [
        ('q1', 'one_tooth'),
        ('a1', 'has_implant_needs_crown'),
        ('implant_system', 'premium'),
      ]);
      expect(find.text('Постійна коронка на наявний імплант'), findsOneWidget);
      await backTo(tester, q('implant_system'));
      await backTo(tester, q('a1'));
      await backTo(tester, q('q1'));
      await _tapText(tester, 'Назад');
      expect(find.text(cityTitle), findsOneWidget);
      expect(find.text('Назад'), findsNothing);
      // City screen works again.
      await _tapText(tester, _cityCv);
      expect(find.text(q('q1')), findsOneWidget);
    });

    testWidgets('B: result -> implant_system -> b2 -> b1 -> q1 -> city', (
      tester,
    ) async {
      await _startAt(tester, _cityIf);
      await _answer(tester, const [
        ('q1', 'few_2_3'),
        ('b1', 'three'),
        ('b2', 'has_implants'),
        ('implant_system', 'standard'),
      ]);
      expect(
        find.text('Постійна 3 коронки на 2 наявних імплантах'),
        findsOneWidget,
      );
      await backTo(tester, q('implant_system'));
      await backTo(tester, q('b2'));
      await backTo(tester, q('b1'));
      await backTo(tester, q('q1'));
      await _tapText(tester, 'Назад');
      expect(find.text(cityTitle), findsOneWidget);
    });

    testWidgets('A: back from a1 result re-answers a1 differently', (
      tester,
    ) async {
      await _startAt(tester, _cityIf);
      await _answer(tester, const [
        ('q1', 'one_tooth'),
        ('a1', 'replace_implant_or_crown'),
      ]);
      expect(find.textContaining(_msgReplace), findsOneWidget);
      await backTo(tester, q('a1'));
      await _tapText(tester, _optionLabel('a1', 'already_removed'));
      expect(find.text('1 імплант + 1 коронка'), findsOneWidget);
      expect(find.textContaining(_msgReplace), findsNothing);
      expect(find.text(_gateTitle), findsOneWidget);
    });

    testWidgets('B: back from result and change b2 to has_implants', (
      tester,
    ) async {
      await _startAt(tester, _cityIf);
      await _answer(tester, const [
        ('q1', 'few_2_3'),
        ('b1', 'two'),
        ('b2', 'all_removed'),
      ]);
      expect(find.text('2 імпланти + 2 коронки'), findsOneWidget);
      await backTo(tester, q('b2'));
      await _tapText(tester, _optionLabel('b2', 'has_implants'));
      expect(find.text(q('implant_system')), findsOneWidget);
      await _tapText(tester, _optionLabel('implant_system', 'premium'));
      expect(
        find.text('Постійна 2 коронки на 2 наявних імплантах'),
        findsOneWidget,
      );
      expect(find.text('2 імпланти + 2 коронки'), findsNothing);
    });

    // A -> (back to q1) -> B, and B -> (back to q1) -> A, with the first
    // result left in various states.
    for (final stage in const ['untouched', 'phone revealed', 'booked']) {
      for (final fromA in const [true, false]) {
        final label = fromA ? 'A then B' : 'B then A';
        final testName = 'Different branch after back ($label), first '
            'result $stage';
        testWidgets(
          testName,
          (tester) async {
            await _startAt(tester, _cityIf);
            final first = fromA
                ? const [
                    ('q1', 'one_tooth'),
                    ('a1', 'already_removed'),
                  ]
                : const [
                    ('q1', 'few_2_3'),
                    ('b1', 'two'),
                    ('b2', 'all_removed'),
                  ];
            final firstSummary =
                fromA ? '1 імплант + 1 коронка' : '2 імпланти + 2 коронки';
            await _answer(tester, first);
            expect(find.text(firstSummary), findsOneWidget);
            if (stage != 'untouched') {
              await _enterPhone(tester);
              await _tickConsent(tester);
              await _tapText(tester, _showBtn);
              expect(find.textContaining('€'), findsWidgets);
            }
            if (stage == 'booked') await _book(tester, _bookBtn);

            // Walk all the way back to q1.
            var steps = first.length - 1;
            while (steps-- > 0) {
              await _tapText(tester, 'Назад');
            }
            await _tapText(tester, 'Назад');
            expect(find.text(q('q1')), findsOneWidget);

            final second = fromA
                ? const [
                    ('q1', 'few_2_3'),
                    ('b1', 'three'),
                    ('b2', 'all_removed'),
                  ]
                : const [
                    ('q1', 'one_tooth'),
                    ('a1', 'recommended_removal'),
                  ];
            final secondSummary =
                fromA ? '2 імпланти + 3 коронки' : '1 імплант + 1 коронка';
            await _answer(tester, second);
            expect(find.text(secondSummary), findsOneWidget);
            expect(find.text(firstSummary), findsNothing);
            // The phone, once given, is kept for the new scenario; a booking
            // made for the old scenario is not carried over.
            if (stage == 'untouched') {
              expect(find.text(_gateTitle), findsOneWidget);
              expect(find.textContaining('€'), findsNothing);
            } else {
              expect(find.text(_gateTitle), findsNothing);
              expect(find.textContaining('€'), findsWidgets);
              expect(find.text(_bookBtn), findsOneWidget);
            }
            expect(find.textContaining(_thanks), findsNothing);
          },
        );
      }
    }

    testWidgets('Individual result -> back -> priced branch B', (
      tester,
    ) async {
      await _startAt(tester, _cityIf);
      await _answer(tester, const [
        ('q1', 'one_tooth'),
        ('a1', 'has_implant_needs_crown'),
        ('implant_system', 'unknown'),
      ]);
      expect(find.textContaining(_msgUnknownSystem), findsOneWidget);
      await backTo(tester, q('implant_system'));
      await backTo(tester, q('a1'));
      await backTo(tester, q('q1'));
      await _answer(tester, const [
        ('q1', 'few_2_3'),
        ('b1', 'two'),
        ('b2', 'still_present'),
      ]);
      expect(find.text('2 імпланти + 2 коронки'), findsOneWidget);
      expect(find.textContaining(_msgUnknownSystem), findsNothing);
      expect(find.text(_gateTitle), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
    });
  });
}
