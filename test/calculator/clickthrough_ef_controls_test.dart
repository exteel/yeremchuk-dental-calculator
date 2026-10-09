// Click-through coverage for branches E/F (full jaw) and for every control on
// the result screen (city chips, tier chips, comparison cards, temp-crown
// checkbox, All-on 4/6/8 cards, phone gate, back button, consult-only CTA).
//
// Expected numbers are computed here from literal catalog prices (ТЗ §3) with
// independent formulas - nothing is read back from PricingEngine.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/screens/implant_calculator_screen.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';

import '../helpers/helpers.dart';

// ---------------------------------------------------------------------------
// Labels
// ---------------------------------------------------------------------------
const ifCity = 'Івано-Франківськ';
const cvCity = 'Чернівці';
const cities = [ifCity, cvCity];

const q1Full1 = 'Більшість або всі зуби на одній щелепі';
const q1Both = 'Зуби на обох щелепах';
const q1One = 'Один зуб';
const oneRemoved = 'Зуб уже видалений';
const oneReplace = 'Заміна імпланта або коронки';

const eOptions = [
  'Зубів немає',
  'Рухомі зуби',
  'Більшість зруйновані',
  'Знімний протез',
  'Уже є конструкція на імплантах',
  'Не знаю',
];
const fOptions = [
  'Зубів немає',
  'Рухомі або зруйновані',
  'Одна щелепа без зубів',
  'Знімні протези',
  'Наявні конструкції на імплантах',
  'Не знаю',
];

const tierNames = ['Базовий', 'Оптимальний', 'Преміальний'];

const tempLabel = 'Потрібна тимчасова коронка на період лікування';
const gateButton = 'Показати розрахунок';
const bookButton = 'Хочу записатися на консультацію';
const consultButton = 'Записатися на консультацію';
const validPhone = '0501234567';

const existingConstructionMessage =
    'Оцінка наявної конструкції на імплантах потребує огляду та КТ — '
    'точну вартість заміни попередньо визначити неможливо.';
const replaceMessage =
    'Заміна наявного імпланта або коронки потребує індивідуальної оцінки '
    'стану кістки та конструкції.';

// ---------------------------------------------------------------------------
// Independent price model (literal numbers from the price list)
// ---------------------------------------------------------------------------
String fmt(num v) {
  final digits = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(' ');
    b.write(digits[i]);
  }
  return b.toString();
}

String eur(num v) => '${fmt(v)} €';
String uah(num v) => '${fmt(v)} грн';
num round100(num v) => (v / 100).round() * 100;
int digitsOf(String s) => int.parse(s.replaceAll(RegExp(r'\D'), ''));

// one tooth / bridge implants: Neodent, Straumann, Straumann White
const toothImplNames = ['Neodent', 'Straumann', 'Straumann White'];
const toothImplEur = [480, 780, 1200];
const toothImplPremium = [false, true, true];
const crownNames = [
  'Монолітний цирконій без індивідуального нанесення',
  'Багатошаровий монолітний цирконій',
  'Цирконій з індивідуальним нанесенням',
];
Map<String, List<int>> crownEur = {
  ifCity: [300, 500, 1000],
  cvCity: [200, 300, 500],
};

// full arch implants
const archImplNames = ['Neodent', 'Straumann', 'Straumann SLA Active'];
const archImplEur = [480, 780, 850];
const archImplPremium = [false, true, true];
const archFinalNames = [
  'Металокерамічна постійна конструкція',
  'Цирконій на фрезерованій титановій балці',
  'Преміальний цирконій на титановій балці',
];
const archFinalEur = [2900, 4900, 7800];
const archTempName =
    'Тимчасова пластмасова конструкція на металевому каркасі';

int supraEur(bool prem) => prem ? 200 : 100;
String supraName(bool prem) =>
    prem ? 'Комплект супраструктур: преміум' : 'Комплект супраструктур: стандарт';
int healUah(bool prem, String city) =>
    prem ? (city == ifCity ? 5000 : 4500) : 3500;
String healName(bool prem) =>
    prem ? 'Формувач: Straumann-група' : 'Формувач: Neodent-група';
int abutEur(bool prem) => prem ? 100 : 50;
String abutName(bool prem) =>
    prem ? 'Додатковий абатмент: преміум' : 'Додатковий абатмент: стандарт';
int muEur(bool prem) => prem ? 118 : 65;
String muName(bool prem) =>
    prem ? 'Мультиюніт: Straumann-група' : 'Мультиюніт: Neodent-група';

int toothEur(String city, int i, int j, {bool temp = false}) =>
    toothImplEur[i] +
    supraEur(toothImplPremium[i]) +
    crownEur[city]![j] +
    (temp ? abutEur(toothImplPremium[i]) : 0);
int toothUah(String city, int i, {bool temp = false}) =>
    healUah(toothImplPremium[i], city) + 3400 + (temp ? 2100 + 3400 : 0);

int archFirst(int n, int i, int jaws) =>
    jaws * (n * (archImplEur[i] + muEur(archImplPremium[i])) + 1000);
int archFull(int n, int i, int j, int jaws) =>
    archFirst(n, i, jaws) + jaws * archFinalEur[j];

// ---------------------------------------------------------------------------
// UI helpers
// ---------------------------------------------------------------------------
Future<void> tall(WidgetTester t) async {
  t.view.physicalSize = const Size(900, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> tapF(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> tapText(WidgetTester t, String text) =>
    tapF(t, find.text(text).first);

Future<void> openResult(
  WidgetTester t,
  List<String> path, {
  String city = ifCity,
}) async {
  await tall(t);
  await t.pumpApp(const ImplantCalculatorScreen());
  await t.pumpAndSettle();
  await tapF(t, find.text(city));
  for (final p in path) {
    await tapText(t, p);
  }
}

/// Taps a booking/consult button and waits through the 600 ms stub submit.
Future<void> tapAndSubmit(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pump();
  await t.pump(const Duration(milliseconds: 800));
  await t.pumpAndSettle();
}

Finder buttonF(String label) => find.widgetWithText(ElevatedButton, label);
bool enabled(WidgetTester t, String label) =>
    t.widget<ElevatedButton>(buttonF(label)).onPressed != null;

Finder chipF(int index) => find.byType(ChoiceChip).at(index);
// chip order on every priced result: city 0,1; primary tier 2..4; secondary 5..7
Future<void> tapCity(WidgetTester t, int c) => tapF(t, chipF(c));
Future<void> tapPrimary(WidgetTester t, int i) => tapF(t, chipF(2 + i));
Future<void> tapSecondary(WidgetTester t, int j) => tapF(t, chipF(5 + j));

void expectChips(WidgetTester t, {int? city, int? p, int? s}) {
  final chips = t.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
  expect(chips.length, 8, reason: '2 city + 3 + 3 tier chips');
  final selected = <int>[for (var k = 0; k < 8; k++) if (chips[k].selected) k];
  final want = <int>[if (city != null) city, if (p != null) 2 + p, if (s != null) 5 + s];
  expect(selected, want, reason: 'selected chips');
  final labels = [
    for (final c in chips) ((c.label as Text).data ?? ''),
  ];
  expect(labels, [ifCity, cvCity, ...tierNames, ...tierNames]);
}

Future<void> reveal(WidgetTester t, {String phone = validPhone}) async {
  await t.enterText(find.byType(TextField), phone);
  await t.pump();
  await tapF(t, find.byType(Checkbox).last);
  expect(enabled(t, gateButton), isTrue);
  await tapF(t, buttonF(gateButton));
  expect(find.text(gateButton), findsNothing);
}

/// All Text strings inside the revealed-total panel, in tree order.
List<String> revealed(WidgetTester t) {
  final col = find
      .ancestor(
        of: find.textContaining('за курсом НБУ'),
        matching: find.byType(Column),
      )
      .first;
  return t
      .widgetList<Text>(find.descendant(of: col, matching: find.byType(Text)))
      .map((w) => w.data ?? '')
      .toList();
}

List<String> pairsAfterApprox(List<String> texts) {
  final k = texts.indexWhere((s) => s.startsWith('≈'));
  return texts.sublist(k + 1);
}

List<String> flat(List<(String, String)> pairs) =>
    [for (final p in pairs) ...[p.$1, p.$2]];

void expectToothTotal(
  WidgetTester t,
  String city,
  int i,
  int j, {
  bool temp = false,
}) {
  final texts = revealed(t);
  final e = toothEur(city, i, j, temp: temp);
  final u = toothUah(city, i, temp: temp);
  final prem = toothImplPremium[i];
  expect(texts[0], eur(e), reason: '$city impl=$i crown=$j temp=$temp');
  expect(texts[1], '≈ ${uah(round100(e * nbuEurRateFallback + u))} за курсом НБУ');
  expect(pairsAfterApprox(texts), flat([
    ('${toothImplNames[i]} × 1 (імплант + встановлення)', eur(toothImplEur[i])),
    ('${supraName(prem)} × 1', eur(supraEur(prem))),
    ('${crownNames[j]} × 1', eur(crownEur[city]![j])),
    ('${healName(prem)} × 1', uah(healUah(prem, city))),
    ('Сканування обох щелеп', uah(3400)),
    if (temp) ...[
      ('${abutName(prem)} × 1 (тимчасова)', eur(abutEur(prem))),
      ('Тимчасова коронка/одиниця моста × 1', uah(2100)),
      ('Повторне сканування', uah(3400)),
    ],
  ]));
}

void expectArchTotal(WidgetTester t, int n, int i, int j, int jaws) {
  final texts = revealed(t);
  final first = archFirst(n, i, jaws);
  final full = archFull(n, i, j, jaws);
  final prem = archImplPremium[i];
  final both = jaws == 2 ? ' × 2 щелепи' : '';
  final why = 'n=$n impl=$i final=$j jaws=$jaws';
  expect(texts[0], 'Перший етап — тимчасові зуби за 3–7 днів');
  expect(texts[1], '${eur(first)} + ${uah(3400)}', reason: why);
  expect(texts[2], 'Постійна конструкція — приблизно через 6 місяців');
  expect(texts[3], '+ ${eur(full - first)} + ${uah(6800 - 3400)}', reason: why);
  expect(texts[4], 'Загальна вартість до постійної конструкції');
  expect(texts[5], '${eur(full)} + ${uah(6800)}', reason: why);
  expect(texts[6], '≈ ${uah(round100(full * nbuEurRateFallback + 6800))} за курсом НБУ',
      reason: why);
  expect(pairsAfterApprox(texts), flat([
    ('${archImplNames[i]} × ${n * jaws}', eur(jaws * n * archImplEur[i])),
    ('${muName(prem)} × ${n * jaws}', eur(jaws * n * muEur(prem))),
    ('$archTempName$both', eur(jaws * 1000)),
    ('${archFinalNames[j]}$both', eur(jaws * archFinalEur[j])),
  ]), reason: why);
  // size cards show the first-stage figure at the current tiers
  for (final k in const [4, 6, 8]) {
    expect(find.text('Перший етап: ${eur(archFirst(k, i, jaws))}'),
        findsOneWidget,
        reason: 'size card $k $why');
  }
}

bool sizeCardCurrent(WidgetTester t, int n) {
  final card = find.widgetWithText(InkWell, 'All-on-$n').first;
  final c = t.widget<Container>(
    find.descendant(of: card, matching: find.byType(Container)).first,
  );
  return (c.decoration! as BoxDecoration).color == AppColors.tealSoft;
}

Future<void> tapSizeCard(WidgetTester t, int n) =>
    tapF(t, find.widgetWithText(InkWell, 'All-on-$n').first);

void expectSizeSelected(WidgetTester t, int n, {required bool both}) {
  final suffix = both ? ' на обох щелепах' : '';
  // headline + the current size card carry the same label
  for (final k in const [4, 6, 8]) {
    expect(sizeCardCurrent(t, k), k == n, reason: 'card $k current?');
  }
  expect(find.text('All-on-$n$suffix'), findsWidgets);
  if (both) {
    expect(find.text('All-on-$n на обох щелепах'), findsOneWidget);
    for (final k in const [4, 6, 8]) {
      if (k != n) {
        expect(find.text('All-on-$k на обох щелепах'), findsNothing);
      }
    }
  } else {
    expect(find.text('All-on-$n'), findsNWidgets(2)); // headline + card
    for (final k in const [4, 6, 8]) {
      if (k != n) expect(find.text('All-on-$k'), findsOneWidget); // card only
    }
  }
}

class Card3 {
  Card3(this.status, this.label, this.amount);
  final String status;
  final String label;
  final String amount;
}

List<Card3> comboCards(WidgetTester t) {
  final inks = find.ancestor(
    of: find.byWidgetPredicate(
      (w) => w is Text && (w.data == 'Поточна' || w.data == 'Обрати'),
    ),
    matching: find.byType(InkWell),
  );
  final out = <Card3>[];
  for (var k = 0; k < inks.evaluate().length; k++) {
    final texts = t
        .widgetList<Text>(
          find.descendant(of: inks.at(k), matching: find.byType(Text)),
        )
        .map((w) => w.data ?? '')
        .toList();
    out.add(Card3(texts[0], texts[1], texts[2]));
  }
  return out;
}

Finder comboCardFinder(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(InkWell),
    );

/// Expected (label -> eur) of the nearest-three window around the current one.
List<String> expectedCardLabels(String city, int ci, int cj, {bool temp = false}) {
  final all = <(int, String, bool)>[
    for (var i = 0; i < 3; i++)
      for (var j = 0; j < 3; j++)
        (
          toothEur(city, i, j, temp: temp),
          '${toothImplNames[i]} · ${crownNames[j]}',
          i == ci && j == cj,
        ),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final k = all.indexWhere((e) => e.$3);
  return [
    if (k > 0) all[k - 1].$2,
    all[k].$2,
    if (k < all.length - 1) all[k + 1].$2,
  ];
}

(int, int) indicesOfLabel(String label) {
  final parts = label.split(' · ');
  return (toothImplNames.indexOf(parts[0]), crownNames.indexOf(parts[1]));
}

// ---------------------------------------------------------------------------
void main() {
  // =========================================================================
  group('Branch E (одна щелепа) - every e1 option', () {
    for (var o = 0; o < eOptions.length; o++) {
      final opt = eOptions[o];
      if (opt == 'Уже є конструкція на імплантах') {
        testWidgets('E / $opt -> consult-only result', (t) async {
          await openResult(t, [q1Full1, opt]);
          expect(find.text(existingConstructionMessage), findsOneWidget);
          expect(find.textContaining('€'), findsNothing);
          expect(find.text(gateButton), findsNothing);
          expect(find.byType(ChoiceChip), findsNothing);
          expect(find.textContaining('All-on'), findsNothing);
          expect(enabled(t, consultButton), isFalse);
          await t.enterText(find.byType(TextField), validPhone);
          await t.pump();
          expect(enabled(t, consultButton), isFalse, reason: 'no consent yet');
          await tapF(t, find.byType(Checkbox).last);
          expect(enabled(t, consultButton), isTrue);
          await tapAndSubmit(t, buttonF(consultButton));
          expect(find.textContaining('Дякуємо!'), findsOneWidget);
          expect(buttonF(consultButton), findsNothing);
        });
      } else {
        testWidgets('E / $opt -> All-on-6 default, gate, reveal, book',
            (t) async {
          await openResult(t, [q1Full1, opt]);
          // --- before the phone: no money anywhere, incl. 4/6/8 cards
          expect(find.textContaining('€'), findsNothing);
          expect(find.textContaining('Перший етап:'), findsNothing);
          for (final n in const [4, 6, 8]) {
            expect(find.widgetWithText(InkWell, 'All-on-$n'), findsOneWidget);
          }
          expectSizeSelected(t, 6, both: false);
          expect(find.text('Ваш персональний розрахунок готовий'),
              findsOneWidget);
          expect(enabled(t, gateButton), isFalse);
          expect(find.text(tempLabel), findsNothing);
          expect(find.textContaining('Даних поки недостатньо'),
              opt == 'Не знаю' ? findsOneWidget : findsNothing);
          expect(find.text('Рівень імпланта'), findsOneWidget);
          expect(find.text('Рівень постійної конструкції'), findsOneWidget);
          expectChips(t, city: 0, p: 1, s: 1);
          // --- reveal
          await reveal(t);
          expectArchTotal(t, 6, 1, 1, 1);
          expect(eur(archFull(6, 1, 1, 1)), '11 288 €');
          expect(find.textContaining('Прості рухомі зуби'), findsOneWidget);
          expect(find.textContaining('Консультація імплантолога в місті $ifCity'),
              findsOneWidget);
          // --- book
          await tapAndSubmit(t, buttonF(bookButton));
          expect(find.textContaining('Дякуємо!'), findsOneWidget);
          expect(buttonF(bookButton), findsNothing);
        });
      }
    }
  });

  // =========================================================================
  group('Branch F (обидві щелепи) - every f1 option', () {
    for (var o = 0; o < fOptions.length; o++) {
      final opt = fOptions[o];
      if (opt == 'Наявні конструкції на імплантах') {
        testWidgets('F / $opt -> consult-only result', (t) async {
          await openResult(t, [q1Both, opt]);
          expect(find.text(existingConstructionMessage), findsOneWidget);
          expect(find.textContaining('€'), findsNothing);
          expect(find.text(gateButton), findsNothing);
          expect(find.byType(ChoiceChip), findsNothing);
          expect(enabled(t, consultButton), isFalse);
          await tapF(t, find.byType(Checkbox).last);
          expect(enabled(t, consultButton), isFalse, reason: 'no phone yet');
          await t.enterText(find.byType(TextField), validPhone);
          await t.pump();
          expect(enabled(t, consultButton), isTrue);
          await tapAndSubmit(t, buttonF(consultButton));
          expect(find.textContaining('Дякуємо!'), findsOneWidget);
        });
      } else {
        testWidgets('F / $opt -> All-on-6 на обох щелепах, double EUR',
            (t) async {
          await openResult(t, [q1Both, opt]);
          expect(find.textContaining('€'), findsNothing);
          expect(find.textContaining('Перший етап:'), findsNothing);
          for (final n in const [4, 6, 8]) {
            expect(find.widgetWithText(InkWell, 'All-on-$n'), findsOneWidget);
          }
          expectSizeSelected(t, 6, both: true);
          expect(enabled(t, gateButton), isFalse);
          expect(find.textContaining('Даних поки недостатньо'),
              opt == 'Не знаю' ? findsOneWidget : findsNothing);
          expectChips(t, city: 0, p: 1, s: 1);
          await reveal(t);
          expectArchTotal(t, 6, 1, 1, 2);
          expect(find.textContaining('Прості рухомі зуби'), findsOneWidget);
          // exactly double the one-jaw figure, EUR only
          expect(archFull(6, 1, 1, 2), 2 * archFull(6, 1, 1, 1));
          expect(archFirst(6, 1, 2), 2 * archFirst(6, 1, 1));
          await tapAndSubmit(t, buttonF(bookButton));
          expect(find.textContaining('Дякуємо!'), findsOneWidget);
        });
      }
    }

    testWidgets('F figures on screen are exactly 2x E (EUR), same scan UAH',
        (t) async {
      await openResult(t, [q1Full1, 'Зубів немає']);
      await reveal(t);
      final e = revealed(t);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await openResult(t, [q1Both, 'Зубів немає']);
      await reveal(t);
      final f = revealed(t);
      for (final k in const [1, 3, 5]) {
        final eParts = e[k].split(' + ');
        final fParts = f[k].split(' + ');
        // '+ X €' prefix on index 3
        expect(digitsOf(fParts[eParts.length - 2]) ,
            2 * digitsOf(eParts[eParts.length - 2]),
            reason: 'EUR part of line $k: ${e[k]} vs ${f[k]}');
        expect(fParts.last, eParts.last, reason: 'UAH part unchanged line $k');
      }
      expect(e[5], '11 288 € + 6 800 грн');
      expect(f[5], '22 576 € + 6 800 грн');
    });
  });

  // =========================================================================
  group('Result screen: city chips', () {
    testWidgets('one tooth: IF <-> CV chips reprice (1480 vs 1280) live',
        (t) async {
      await openResult(t, [q1One, oneRemoved]);
      expectChips(t, city: 0, p: 1, s: 1);
      await reveal(t);
      expect(revealed(t)[0], '1 480 €');
      expect(find.textContaining('Консультація імплантолога в місті $ifCity — 600 грн'),
          findsOneWidget);
      expect(find.textContaining('Пн–Сб 08:00–20:00'), findsOneWidget);

      await tapCity(t, 1);
      expectChips(t, city: 1, p: 1, s: 1);
      expect(revealed(t)[0], '1 280 €');
      expectToothTotal(t, cvCity, 1, 1);
      expect(find.textContaining('Консультація імплантолога в місті $cvCity — 550 грн'),
          findsOneWidget);
      expect(find.textContaining('Пн–Пт 09:00–19:00'), findsOneWidget);

      await tapCity(t, 0);
      expectChips(t, city: 0, p: 1, s: 1);
      expect(revealed(t)[0], '1 480 €');
      expectToothTotal(t, ifCity, 1, 1);
      // tapping the already selected chip keeps it selected
      await tapCity(t, 0);
      expectChips(t, city: 0, p: 1, s: 1);
    });

    testWidgets('city switched BEFORE the reveal is honoured by the reveal',
        (t) async {
      await openResult(t, [q1One, oneRemoved]);
      await tapCity(t, 1);
      expectChips(t, city: 1, p: 1, s: 1);
      expect(find.textContaining('€'), findsNothing);
      await reveal(t);
      expectToothTotal(t, cvCity, 1, 1);
      expect(revealed(t)[0], '1 280 €');
    });

    for (final jaws in [1, 2]) {
      testWidgets('All-on (${jaws == 1 ? 'E' : 'F'}): city chips switch, '
          'consult info follows, EUR unchanged', (t) async {
        await openResult(t, [jaws == 1 ? q1Full1 : q1Both, 'Зубів немає']);
        await reveal(t);
        expectArchTotal(t, 6, 1, 1, jaws);
        await tapCity(t, 1);
        expectChips(t, city: 1, p: 1, s: 1);
        expectArchTotal(t, 6, 1, 1, jaws);
        expect(find.textContaining('в місті $cvCity — 550 грн'),
            findsOneWidget);
        await tapCity(t, 0);
        expectChips(t, city: 0, p: 1, s: 1);
        expect(find.textContaining('в місті $ifCity — 600 грн'),
            findsOneWidget);
      });
    }
  });

  // =========================================================================
  group('Result screen: 9 implant x crown tier chip combos (one tooth)', () {
    for (final city in cities) {
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          testWidgets('$city: implant=${tierNames[i]} crown=${tierNames[j]} '
              '(chips set BEFORE reveal)', (t) async {
            await openResult(t, [q1One, oneRemoved], city: city);
            // go somewhere else first so each chip is really clicked
            await tapPrimary(t, (i + 1) % 3);
            await tapSecondary(t, (j + 1) % 3);
            await tapPrimary(t, i);
            await tapSecondary(t, j);
            expectChips(t, city: cities.indexOf(city), p: i, s: j);
            expect(find.textContaining('€'), findsNothing);
            await reveal(t);
            expectChips(t, city: cities.indexOf(city), p: i, s: j);
            expectToothTotal(t, city, i, j);
          });
        }
      }
    }

    testWidgets('spec examples: Базовий/Базовий IF 880, Опт/Опт 1480, '
        'Преміальний/Преміальний 2400', (t) async {
      await openResult(t, [q1One, oneRemoved]);
      await reveal(t);
      for (final (i, j, want) in [(0, 0, '880 €'), (1, 1, '1 480 €'), (2, 2, '2 400 €')]) {
        await tapPrimary(t, i);
        await tapSecondary(t, j);
        expect(revealed(t)[0], want);
      }
    });

    for (final city in cities) {
      testWidgets('$city: chips clicked AFTER the reveal reprice live '
          '(all 9 in sequence)', (t) async {
        await openResult(t, [q1One, oneRemoved], city: city);
        await reveal(t);
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            await tapPrimary(t, i);
            await tapSecondary(t, j);
            expectChips(t, city: cities.indexOf(city), p: i, s: j);
            expectToothTotal(t, city, i, j);
          }
        }
      });
    }
  });

  // =========================================================================
  group('Result screen: three comparison cards (one tooth)', () {
    for (var ci = 0; ci < 3; ci++) {
      for (var cj = 0; cj < 3; cj++) {
        testWidgets('start ${tierNames[ci]}/${tierNames[cj]}: cards window, '
            'each non-current card applies', (t) async {
          await openResult(t, [q1One, oneRemoved]);
          await reveal(t);
          await tapPrimary(t, ci);
          await tapSecondary(t, cj);

          final labels = expectedCardLabels(ifCity, ci, cj);
          var cards = comboCards(t);
          expect(cards.map((c) => c.label).toSet(), labels.toSet(),
              reason: 'card set');
          expect(cards.length, labels.length);
          expect(cards.where((c) => c.status == 'Поточна').length, 1);
          final current = cards.firstWhere((c) => c.status == 'Поточна');
          expect(current.amount, revealed(t)[0]);
          for (final c in cards) {
            final (ii, jj) = indicesOfLabel(c.label);
            expect(c.amount, eur(toothEur(ifCity, ii, jj)),
                reason: 'amount on card ${c.label}');
          }
          // tapping the current card is inert
          await tapF(t, comboCardFinder(current.label).first);
          expect(revealed(t)[0], current.amount);
          expectChips(t, city: 0, p: ci, s: cj);

          final before = revealed(t)[0];
          final targets =
              cards.where((c) => c.status != 'Поточна').map((c) => c.label);
          for (final target in targets) {
            // restore start state, then tap the card
            await tapPrimary(t, ci);
            await tapSecondary(t, cj);
            expect(revealed(t)[0], before);
            await tapF(t, comboCardFinder(target).first);
            final (ti, tj) = indicesOfLabel(target);
            expectChips(t, city: 0, p: ti, s: tj);
            expectToothTotal(t, ifCity, ti, tj);
            expect(revealed(t)[0], isNot(before),
                reason: 'sum must change after tapping card $target');
            cards = comboCards(t);
            final cur = cards.firstWhere((c) => c.status == 'Поточна');
            expect(cur.label, target);
            expect(cur.amount, revealed(t)[0]);
            expect(cards.map((c) => c.label).toSet(),
                expectedCardLabels(ifCity, ti, tj).toSet());
          }
        });
      }
    }
  });

  // =========================================================================
  group('Result screen: temp-crown checkbox (one tooth)', () {
    testWidgets('present, off by default; toggle (checkbox and label) '
        'changes breakdown + sum for all 9 tier combos', (t) async {
      await openResult(t, [q1One, oneRemoved]);
      expect(find.text(tempLabel), findsOneWidget);
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
      await reveal(t);
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          await tapPrimary(t, i);
          await tapSecondary(t, j);
          expectToothTotal(t, ifCity, i, j);
          final base = revealed(t)[0];
          // on via the checkbox itself
          await tapF(t, find.byType(Checkbox).first);
          expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
          expectToothTotal(t, ifCity, i, j, temp: true);
          expect(revealed(t)[0], isNot(base));
          // comparison cards follow the temp-crown surcharge
          final labels = expectedCardLabels(ifCity, i, j, temp: true);
          final cards = comboCards(t);
          expect(cards.map((c) => c.label).toSet(), labels.toSet());
          for (final c in cards) {
            final (ii, jj) = indicesOfLabel(c.label);
            expect(c.amount, eur(toothEur(ifCity, ii, jj, temp: true)));
          }
          // off via the label (row InkWell)
          await tapText(t, tempLabel);
          expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
          expect(revealed(t)[0], base);
          expectToothTotal(t, ifCity, i, j);
        }
      }
    });

    testWidgets('toggled BEFORE the reveal is applied; CV too', (t) async {
      await openResult(t, [q1One, oneRemoved], city: cvCity);
      await tapText(t, tempLabel);
      expect(find.textContaining('€'), findsNothing);
      await reveal(t);
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
      expectToothTotal(t, cvCity, 1, 1, temp: true);
      expect(find.textContaining('Повторне сканування'), findsOneWidget);
      await tapF(t, find.byType(Checkbox).first);
      expectToothTotal(t, cvCity, 1, 1);
      expect(find.textContaining('Повторне сканування'), findsNothing);
    });

    testWidgets('not offered on All-on results (E/F) nor consult-only',
        (t) async {
      await openResult(t, [q1Full1, 'Зубів немає']);
      expect(find.text(tempLabel), findsNothing);
      await t.pumpWidget(const SizedBox());
      await openResult(t, [q1Both, 'Зубів немає']);
      expect(find.text(tempLabel), findsNothing);
      await t.pumpWidget(const SizedBox());
      await openResult(t, [q1One, oneReplace]);
      expect(find.text(tempLabel), findsNothing);
    });
  });

  // =========================================================================
  group('Result screen: All-on 4/6/8 cards + tier chips', () {
    for (final jaws in [1, 2]) {
      for (final city in cities) {
        for (final n in const [4, 6, 8]) {
          testWidgets('${jaws == 1 ? 'E' : 'F'} $city All-on-$n: card click, '
              '9 implant x construction combos', (t) async {
            await openResult(
              t,
              [jaws == 1 ? q1Full1 : q1Both, 'Зубів немає'],
              city: city,
            );
            final cc = cities.indexOf(city);
            // pre-reveal: size card click works and re-labels the headline
            for (final k in [n == 4 ? 6 : 4, n]) {
              await tapSizeCard(t, k);
              expectSizeSelected(t, k, both: jaws == 2);
            }
            expect(find.textContaining('€'), findsNothing);
            await reveal(t);
            expectSizeSelected(t, n, both: jaws == 2);
            for (var i = 0; i < 3; i++) {
              for (var j = 0; j < 3; j++) {
                await tapPrimary(t, i);
                await tapSecondary(t, j);
                expectChips(t, city: cc, p: i, s: j);
                expectArchTotal(t, n, i, j, jaws);
                expectSizeSelected(t, n, both: jaws == 2);
              }
            }
          });
        }
      }
    }

    testWidgets('after reveal every 4/6/8 card changes headline and sum',
        (t) async {
      await openResult(t, [q1Full1, 'Рухомі зуби']);
      await reveal(t);
      final seen = <String>{};
      for (final n in const [4, 8, 6, 4, 6, 8]) {
        await tapSizeCard(t, n);
        expectSizeSelected(t, n, both: false);
        expectArchTotal(t, n, 1, 1, 1);
        seen.add(revealed(t)[5]);
        // permanent construction line + NBU conversion are present
        expect(find.text('Постійна конструкція — приблизно через 6 місяців'),
            findsOneWidget);
        expect(find.textContaining('грн за курсом НБУ'), findsOneWidget);
        expect(revealed(t)[3], startsWith('+ '));
      }
      expect(seen.length, 3, reason: 'three sizes -> three distinct sums');
    });
  });

  // =========================================================================
  group('Result screen: phone gate', () {
    testWidgets('button state matrix + Enter key (one tooth)', (t) async {
      await openResult(t, [q1One, oneRemoved]);
      expect(enabled(t, gateButton), isFalse, reason: 'empty');

      // too short, with consent
      await tapF(t, find.byType(Checkbox).last);
      for (final s in ['0', '050', '050123', '05012345', '050123456']) {
        await t.enterText(find.byType(TextField), s);
        await t.pump();
        expect(enabled(t, gateButton), isFalse, reason: 'short "$s"');
      }
      // clicking the disabled button does nothing
      await t.ensureVisible(buttonF(gateButton));
      await t.pumpAndSettle();
      await t.tap(buttonF(gateButton), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.textContaining('€'), findsNothing);

      // letters are filtered out
      await t.enterText(find.byType(TextField), 'abcdef');
      await t.pump();
      expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');
      expect(enabled(t, gateButton), isFalse);

      // exactly 10 digits -> enabled; formatted 12 digits -> enabled
      await t.enterText(find.byType(TextField), '0501234567');
      await t.pump();
      expect(enabled(t, gateButton), isTrue);
      await t.enterText(find.byType(TextField), '+38 (050) 123-45-67');
      await t.pump();
      expect(enabled(t, gateButton), isTrue);

      // consent off -> disabled again; on via label -> enabled
      await tapF(t, find.byType(Checkbox).last);
      expect(enabled(t, gateButton), isFalse, reason: 'consent removed');
      await tapText(t,
          'Погоджуюсь на обробку персональних даних і зв’язок щодо консультації');
      expect(enabled(t, gateButton), isTrue, reason: 'consent via label');
      await tapF(t, find.byType(Checkbox).last);
      expect(enabled(t, gateButton), isFalse);

      // Enter: valid phone but NO consent -> nothing happens
      await t.enterText(find.byType(TextField), validPhone);
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text(gateButton), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);

      // Enter: consent but short phone -> nothing happens
      await tapF(t, find.byType(Checkbox).last);
      await t.enterText(find.byType(TextField), '05012');
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text(gateButton), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);

      // Enter: valid phone + consent -> reveal
      await t.enterText(find.byType(TextField), validPhone);
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text(gateButton), findsNothing);
      expectToothTotal(t, ifCity, 1, 1);
    });

    testWidgets('button click with valid phone + consent reveals the sum',
        (t) async {
      await openResult(t, [q1One, oneRemoved]);
      await t.enterText(find.byType(TextField), validPhone);
      await t.pump();
      expect(enabled(t, gateButton), isFalse, reason: 'phone but no consent');
      await tapF(t, find.byType(Checkbox).last);
      expect(enabled(t, gateButton), isTrue);
      await tapF(t, buttonF(gateButton));
      expect(find.text('Ваш персональний розрахунок готовий'), findsNothing);
      expect(revealed(t)[0], '1 480 €');
    });

    testWidgets('same gate on All-on result: Enter reveals', (t) async {
      await openResult(t, [q1Full1, 'Зубів немає']);
      expect(enabled(t, gateButton), isFalse);
      await t.enterText(find.byType(TextField), validPhone);
      await tapF(t, find.byType(Checkbox).last);
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expectArchTotal(t, 6, 1, 1, 1);
    });

    testWidgets('booking button shows spinner while submitting then thanks',
        (t) async {
      await openResult(t, [q1One, oneRemoved]);
      await reveal(t);
      await t.ensureVisible(buttonF(bookButton));
      await t.pumpAndSettle();
      await t.tap(buttonF(bookButton));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(t.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
          isNull);
      await t.pump(const Duration(milliseconds: 800));
      await t.pumpAndSettle();
      expect(find.textContaining('Дякуємо!'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // =========================================================================
  group('Result screen: Назад', () {
    testWidgets('one tooth: result -> a1 -> q1 -> city, re-answer works',
        (t) async {
      await openResult(t, [q1One, oneRemoved]);
      await tapText(t, 'Назад');
      expect(find.text('Яка зараз ситуація із зубом?'), findsOneWidget);
      await tapText(t, oneReplace);
      expect(find.text(replaceMessage), findsOneWidget);
      await tapText(t, 'Назад');
      expect(find.text('Яка зараз ситуація із зубом?'), findsOneWidget);
      await tapText(t, 'Назад');
      expect(find.text('Скільки зубів потрібно відновити?'), findsOneWidget);
      await tapText(t, 'Назад');
      expect(find.text('Розрахуйте орієнтовну вартість імплантації'),
          findsOneWidget);
    });

    testWidgets('E result: Назад -> e1 question, other option -> result; '
        'switching to branch F via q1 prices both jaws', (t) async {
      await openResult(t, [q1Full1, 'Зубів немає']);
      expect(find.text('All-on-6'), findsNWidgets(2));
      await tapText(t, 'Назад');
      expect(find.text('Яка зараз ситуація з щелепою?'), findsOneWidget);
      await tapText(t, 'Уже є конструкція на імплантах');
      expect(find.text(existingConstructionMessage), findsOneWidget);
      await tapText(t, 'Назад');
      await tapText(t, 'Назад');
      expect(find.text('Скільки зубів потрібно відновити?'), findsOneWidget);
      await tapText(t, q1Both);
      await tapText(t, 'Зубів немає');
      expect(find.text('All-on-6 на обох щелепах'), findsOneWidget);
      await reveal(t);
      expectArchTotal(t, 6, 1, 1, 2);
    });

    testWidgets('F result: Назад -> f1 question', (t) async {
      await openResult(t, [q1Both, 'Знімні протези']);
      await tapText(t, 'Назад');
      expect(find.text('Яка зараз ситуація з обома щелепами?'),
          findsOneWidget);
    });

    testWidgets('consult-only result has Назад too', (t) async {
      await openResult(t, [q1One, oneReplace]);
      await tapText(t, 'Назад');
      expect(find.text('Яка зараз ситуація із зубом?'), findsOneWidget);
    });
  });

  // =========================================================================
  group('Consult-only result (Один зуб -> Заміна імпланта або коронки)', () {
    testWidgets('CTA disabled until valid phone AND consent; then thanks',
        (t) async {
      await openResult(t, [q1One, oneReplace]);
      expect(find.text(replaceMessage), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
      expect(find.text(gateButton), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('Консультація імплантолога в місті $ifCity'),
          findsOneWidget);
      expect(enabled(t, consultButton), isFalse, reason: 'empty');

      await t.enterText(find.byType(TextField), '050123');
      await t.pump();
      expect(enabled(t, consultButton), isFalse, reason: 'short phone');
      await tapF(t, find.byType(Checkbox).last);
      expect(enabled(t, consultButton), isFalse,
          reason: 'short phone + consent');
      await t.enterText(find.byType(TextField), validPhone);
      await t.pump();
      expect(enabled(t, consultButton), isTrue);
      await tapF(t, find.byType(Checkbox).last);
      expect(enabled(t, consultButton), isFalse, reason: 'consent removed');
      await tapText(t,
          'Погоджуюсь на обробку персональних даних і зв’язок щодо консультації');
      expect(enabled(t, consultButton), isTrue);

      await t.ensureVisible(buttonF(consultButton));
      await t.pumpAndSettle();
      await t.tap(buttonF(consultButton));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await t.pump(const Duration(milliseconds: 800));
      await t.pumpAndSettle();
      expect(find.textContaining('Дякуємо!'), findsOneWidget);
      expect(buttonF(consultButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Enter submits only with valid phone + consent', (t) async {
      await openResult(t, [q1One, oneReplace]);
      await t.enterText(find.byType(TextField), validPhone);
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump(const Duration(milliseconds: 800));
      await t.pumpAndSettle();
      expect(find.textContaining('Дякуємо!'), findsNothing, reason: 'no consent');

      await tapF(t, find.byType(Checkbox).last);
      await t.enterText(find.byType(TextField), '0501');
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump(const Duration(milliseconds: 800));
      await t.pumpAndSettle();
      expect(find.textContaining('Дякуємо!'), findsNothing, reason: 'short');

      await t.enterText(find.byType(TextField), validPhone);
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));
      await t.pumpAndSettle();
      expect(find.textContaining('Дякуємо!'), findsOneWidget);
    });

    testWidgets('Chernivtsi consult info shown', (t) async {
      await openResult(t, [q1One, oneReplace], city: cvCity);
      expect(find.textContaining('в місті $cvCity — 550 грн'), findsOneWidget);
    });
  });
}
