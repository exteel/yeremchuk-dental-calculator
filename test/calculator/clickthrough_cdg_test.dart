// Real-UI click-through for branches C (4+ adjacent), D (separate areas) and
// G ("Не знаю" at q1). Every leaf is walked from the city screen to the
// booking confirmation, tapping only what a patient could tap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeremchuk_dental_calculator/calculator/screens/implant_calculator_screen.dart';

import '../helpers/helpers.dart';

const _city = 'Івано-Франківськ';
const _phone = '0671234567';
const _roughBanner = 'Даних поки недостатньо';
const _gateTitle = 'Ваш персональний розрахунок готовий';

/// One leaf of the flow: the labels to tap after the city, then expectations.
class _Leaf {
  const _Leaf(this.name, this.clicks, this.summary, {this.rough = false});

  final String name;
  final List<String> clicks;
  final String summary;
  final bool rough;
}

const _q1C = '4 або більше зубів поруч';
const _q1D = 'Кілька зубів у різних ділянках';
const _q1G = 'Не знаю';

const _leaves = <_Leaf>[
  // ---- Branch C --------------------------------------------------------
  _Leaf('C: Чотири', [_q1C, 'Чотири'], '2 імпланти + 4 коронки'),
  _Leaf('C: Пять', [_q1C, "П'ять"], '3 імпланти + 5 коронок'),
  _Leaf('C: Шість', [_q1C, 'Шість'], '3 імпланти + 6 коронок'),
  _Leaf(
    'C: Сім і більше / Міст на 4 імплантах',
    [_q1C, 'Сім і більше', 'Міст на 4 імплантах зі збереженням власних зубів'],
    '4 імпланти + 7 коронок',
  ),
  _Leaf(
    'C: Сім і більше / Заміна ряду 4/6/8',
    [
      _q1C,
      'Сім і більше',
      'Заміна ряду незнімною конструкцією на 4/6/8 імплантах',
    ],
    'All-on-6',
  ),
  _Leaf(
    'C: Сім і більше / Порівняти обидва',
    [_q1C, 'Сім і більше', 'Порівняти обидва варіанти'],
    'All-on-6',
  ),
  _Leaf(
    'C: Сім і більше / Потрібна рекомендація лікаря',
    [_q1C, 'Сім і більше', 'Потрібна рекомендація лікаря'],
    'All-on-6',
  ),
  _Leaf(
    'C: Не знаю',
    [_q1C, 'Не знаю'],
    '3 імпланти + 6 коронок',
    rough: true,
  ),
  // ---- Branch D --------------------------------------------------------
  _Leaf('D: Два', [_q1D, 'Два'], '2 імпланти + 2 коронки'),
  _Leaf('D: Три', [_q1D, 'Три'], '3 імпланти + 3 коронки'),
  _Leaf('D: Чотири і більше', [_q1D, 'Чотири і більше'], '4 імпланти + 4 коронки'),
  _Leaf(
    'D: Змішана ситуація',
    [_q1D, 'Змішана ситуація'],
    '2 імпланти + 2 коронки',
    rough: true,
  ),
  _Leaf(
    'D: Не знаю',
    [_q1D, 'Не знаю'],
    '2 імпланти + 2 коронки',
    rough: true,
  ),
  // ---- Branch G (each redirect followed one step to a result) -----------
  _Leaf(
    'G: Відсутній один зуб -> a1 Зуб уже видалений',
    [_q1G, 'Відсутній один зуб', 'Зуб уже видалений'],
    '1 імплант + 1 коронка',
  ),
  _Leaf(
    'G: Відсутні декілька зубів поруч -> b1 Два -> b2 Усі вже видалені',
    [_q1G, 'Відсутні декілька зубів поруч', 'Два', 'Усі вже видалені'],
    '2 імпланти + 2 коронки',
  ),
  _Leaf(
    'G: Більшість зубів у поганому стані -> e1 Зубів немає',
    [_q1G, 'Більшість зубів у поганому стані', 'Зубів немає'],
    'All-on-6',
  ),
  _Leaf(
    'G: Не можу визначити',
    [_q1G, 'Не можу визначити'],
    '1 імплант + 1 коронка',
    rough: true,
  ),
];

/// Question each G option must lead to (before reaching a result).
const _gRedirects = <String, String>{
  'Відсутній один зуб': 'Яка зараз ситуація із зубом?',
  'Відсутні декілька зубів поруч': 'Скільки зубів поруч потрібно відновити?',
  'Більшість зубів у поганому стані': 'Яка зараз ситуація з щелепою?',
};

var _taps = 0;
var _leavesDone = 0;

Future<void> _bigSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget, reason: 'target must exist exactly once');
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  _taps++;
}

Future<void> _tap(WidgetTester tester, String label) =>
    _tapFinder(tester, find.text(label));

Future<void> _start(WidgetTester tester) async {
  await _bigSurface(tester);
  await tester.pumpApp(const ImplantCalculatorScreen());
  await tester.pumpAndSettle();
  await _tap(tester, _city);
  expect(find.text('Скільки зубів потрібно відновити?'), findsOneWidget);
}

Finder get _showButton =>
    find.widgetWithText(ElevatedButton, 'Показати розрахунок');

Finder get _euro => find.textContaining('€');

void _expectResult(_Leaf leaf) {
  // Full-arch summary is also the title of the matching size card.
  expect(
    find.text(leaf.summary),
    leaf.summary.startsWith('All-on') ? findsWidgets : findsOneWidget,
    reason: '${leaf.name}: clinical summary',
  );
  expect(
    find.textContaining(_roughBanner),
    leaf.rough ? findsOneWidget : findsNothing,
    reason: '${leaf.name}: rough-estimate banner',
  );
}

/// Phone gate -> revealed sum. Returns once the amount is on screen.
Future<void> _revealSum(WidgetTester tester) async {
  expect(find.text(_gateTitle), findsOneWidget);
  expect(_euro, findsNothing, reason: 'no amount before the phone');

  // Button is disabled until BOTH phone and consent are provided.
  expect(tester.widget<ElevatedButton>(_showButton).onPressed, isNull);
  await tester.enterText(find.byType(TextField), _phone);
  await tester.pumpAndSettle();
  expect(
    tester.widget<ElevatedButton>(_showButton).onPressed,
    isNull,
    reason: 'phone without consent must not enable the button',
  );
  expect(_euro, findsNothing);

  // Result screens may also hold a temp-crown checkbox: pick the consent one.
  final consent = find.descendant(
    of: find
        .ancestor(
          of: find.textContaining('Погоджуюсь на обробку'),
          matching: find.byType(InkWell),
        )
        .first,
    matching: find.byType(Checkbox),
  );
  await _tapFinder(tester, consent);
  expect(tester.widget<Checkbox>(consent).value, isTrue);
  expect(tester.widget<ElevatedButton>(_showButton).onPressed, isNotNull);
  expect(_euro, findsNothing, reason: 'still gated before submit');

  await _tapFinder(tester, _showButton);
  expect(find.text(_gateTitle), findsNothing);
  expect(_euro, findsWidgets, reason: 'amount in € after reveal');
  expect(find.textContaining('грн за курсом НБУ'), findsOneWidget);
  expect(find.textContaining('≈'), findsWidgets);
}

Future<void> _book(WidgetTester tester) async {
  expect(find.textContaining('Дякуємо!'), findsNothing);
  await _tap(tester, 'Хочу записатися на консультацію');
  // Lead service stub: 600 ms delay.
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  expect(find.textContaining('Дякуємо!'), findsOneWidget);
  expect(find.text('Хочу записатися на консультацію'), findsNothing);
}

void main() {
  group('Branches C/D/G click-through', () {
    for (final leaf in _leaves) {
      testWidgets(leaf.name, (tester) async {
        await _start(tester);
        for (final label in leaf.clicks) {
          await _tap(tester, label);
        }
        expect(find.text('Назад'), findsOneWidget, reason: 'back on result');
        _expectResult(leaf);
        await _revealSum(tester);
        _expectResult(leaf);
        await _book(tester);
        _leavesDone++;
      });
    }
  });

  group('Every option of every in-scope question is clickable', () {
    // question screen text -> options, reached via a prefix of clicks.
    final screens = <String, ({List<String> prefix, List<String> options})>{
      'c1': (
        prefix: [_q1C],
        options: ['Чотири', "П'ять", 'Шість', 'Сім і більше', 'Не знаю'],
      ),
      'd1': (
        prefix: [_q1D],
        options: ['Два', 'Три', 'Чотири і більше', 'Змішана ситуація', 'Не знаю'],
      ),
      'g1': (
        prefix: [_q1G],
        options: [
          'Відсутній один зуб',
          'Відсутні декілька зубів поруч',
          'Більшість зубів у поганому стані',
          'Не можу визначити',
        ],
      ),
    };
    for (final entry in screens.entries) {
      for (final option in entry.value.options) {
        testWidgets('${entry.key}: "$option" advances', (tester) async {
          await _start(tester);
          for (final p in entry.value.prefix) {
            await _tap(tester, p);
          }
          // Option is present and a real, enabled button.
          final btn = find.widgetWithText(OutlinedButton, option);
          expect(btn, findsOneWidget);
          expect(tester.widget<OutlinedButton>(btn).onPressed, isNotNull);
          await _tapFinder(tester, btn);
          // Screen changed (question text of the previous screen is gone).
          expect(find.widgetWithText(OutlinedButton, option), findsNothing);
        });
      }
    }

    for (final entry in _gRedirects.entries) {
      testWidgets('g1: "${entry.key}" redirects to "${entry.value}"',
          (tester) async {
        await _start(tester);
        await _tap(tester, _q1G);
        await _tap(tester, entry.key);
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Назад'), findsOneWidget);
      });
    }

    testWidgets('g1: "Не можу визначити" goes straight to a result',
        (tester) async {
      await _start(tester);
      await _tap(tester, _q1G);
      await _tap(tester, 'Не можу визначити');
      expect(find.text(_gateTitle), findsOneWidget);
      expect(find.textContaining(_roughBanner), findsOneWidget);
    });

    testWidgets('c1: "Сім і більше" leads to c2 with four options',
        (tester) async {
      await _start(tester);
      await _tap(tester, _q1C);
      await _tap(tester, 'Сім і більше');
      expect(
        find.text('Що розглядаєте для 7 і більше зубів поруч?'),
        findsOneWidget,
      );
      expect(find.byType(OutlinedButton), findsNWidgets(4));
    });

    testWidgets('"Назад" exists on every in-scope screen', (tester) async {
      await _start(tester);
      await _tap(tester, _q1C);
      expect(find.text('Назад'), findsOneWidget); // c1
      await _tap(tester, 'Сім і більше');
      expect(find.text('Назад'), findsOneWidget); // c2
      await _tap(tester, 'Порівняти обидва варіанти');
      expect(find.text('Назад'), findsOneWidget); // result
    });
  });

  group('Back navigation does not leak stale answers', () {
    testWidgets('C(four) -> back x2 -> D(Два) shows D result', (tester) async {
      await _start(tester);
      await _tap(tester, _q1C);
      await _tap(tester, 'Чотири');
      expect(find.text('2 імпланти + 4 коронки'), findsOneWidget);
      await _tap(tester, 'Назад'); // -> c1
      expect(find.text('Скільки зубів поруч потрібно відновити?'),
          findsOneWidget);
      await _tap(tester, 'Назад'); // -> q1
      expect(find.text('Скільки зубів потрібно відновити?'), findsOneWidget);
      await _tap(tester, _q1D);
      await _tap(tester, 'Два');
      expect(find.text('2 імпланти + 2 коронки'), findsOneWidget);
      expect(find.text('2 імпланти + 4 коронки'), findsNothing);
      expect(find.textContaining(_roughBanner), findsNothing);
    });

    testWidgets('C(7+, All-on-6) -> back x3 -> G(Не можу визначити)',
        (tester) async {
      await _start(tester);
      await _tap(tester, _q1C);
      await _tap(tester, 'Сім і більше');
      await _tap(tester, 'Порівняти обидва варіанти');
      expect(find.text('All-on-6'), findsWidgets);
      await _tap(tester, 'Назад'); // c2
      await _tap(tester, 'Назад'); // c1
      await _tap(tester, 'Назад'); // q1
      await _tap(tester, _q1G);
      await _tap(tester, 'Не можу визначити');
      expect(find.text('1 імплант + 1 коронка'), findsOneWidget);
      expect(find.text('All-on-6'), findsNothing);
      expect(find.textContaining(_roughBanner), findsOneWidget);
    });

    testWidgets('D(Три) -> back x2 -> C(Шість) shows C result',
        (tester) async {
      await _start(tester);
      await _tap(tester, _q1D);
      await _tap(tester, 'Три');
      expect(find.text('3 імпланти + 3 коронки'), findsOneWidget);
      await _tap(tester, 'Назад');
      await _tap(tester, 'Назад');
      await _tap(tester, _q1C);
      await _tap(tester, 'Шість');
      expect(find.text('3 імпланти + 6 коронок'), findsOneWidget);
      expect(find.text('3 імпланти + 3 коронки'), findsNothing);
    });

    testWidgets('G(missing_one) -> a1 -> back -> back -> G(several) -> b1',
        (tester) async {
      await _start(tester);
      await _tap(tester, _q1G);
      await _tap(tester, 'Відсутній один зуб');
      await _tap(tester, 'Зуб уже видалений');
      expect(find.text('1 імплант + 1 коронка'), findsOneWidget);
      await _tap(tester, 'Назад'); // a1
      await _tap(tester, 'Назад'); // g1
      await _tap(tester, 'Відсутні декілька зубів поруч');
      await _tap(tester, 'Три');
      await _tap(tester, 'Усі вже видалені');
      expect(find.text('2 імпланти + 3 коронки'), findsOneWidget);
      expect(find.text('1 імплант + 1 коронка'), findsNothing);
    });

    testWidgets('D(Змішана) rough banner does not leak into C(Чотири)',
        (tester) async {
      await _start(tester);
      await _tap(tester, _q1D);
      await _tap(tester, 'Змішана ситуація');
      expect(find.textContaining(_roughBanner), findsOneWidget);
      await _tap(tester, 'Назад');
      await _tap(tester, 'Назад');
      await _tap(tester, _q1C);
      await _tap(tester, 'Чотири');
      expect(find.text('2 імпланти + 4 коронки'), findsOneWidget);
      expect(find.textContaining(_roughBanner), findsNothing);
    });

    testWidgets(
      'after the sum was revealed, a different branch keeps the given phone '
      'and shows its own sum',
      (tester) async {
        await _start(tester);
        await _tap(tester, _q1C);
        await _tap(tester, 'Чотири');
        await _revealSum(tester);
        await _tap(tester, 'Назад'); // c1
        await _tap(tester, 'Назад'); // q1
        await _tap(tester, _q1D);
        await _tap(tester, 'Три');
        expect(find.text('3 імпланти + 3 коронки'), findsOneWidget);
        expect(_euro, findsWidgets);
        expect(find.text(_gateTitle), findsNothing);
      },
    );

    testWidgets(
      'after booking, going back and picking another branch offers the '
      'booking CTA again (no stale "Дякуємо!")',
      (tester) async {
        await _start(tester);
        await _tap(tester, _q1C);
        await _tap(tester, 'Чотири');
        await _revealSum(tester);
        await _book(tester);
        await _tap(tester, 'Назад');
        await _tap(tester, 'Назад');
        await _tap(tester, _q1D);
        await _tap(tester, 'Три');
        expect(find.textContaining('Дякуємо!'), findsNothing);
      },
    );
  });

  tearDownAll(() {
    // ignore: avoid_print
    print('CDG click-through: $_leavesDone full leaves, $_taps taps.');
  });
}
