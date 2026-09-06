import 'package:flutter_test/flutter_test.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/pricing_engine.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/scenario_resolver.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';

void main() {
  const engine = PricingEngine();

  group('single tooth — worked examples from ТЗ §4.2', () {
    test('Івано-Франківськ: rational/optimal/premium match the ТЗ table', () {
      final rational = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0], // Neodent
        crown: ServiceCatalog.crownTiers[0], // base
        implantCount: 1,
        crownUnits: 1,
      );
      expect(rational.eurAmount, 880);
      expect(rational.uahComponentAmount, 6900);

      final optimal = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[1], // Straumann
        crown: ServiceCatalog.crownTiers[1], // opt
        implantCount: 1,
        crownUnits: 1,
      );
      expect(optimal.eurAmount, 1480);
      expect(optimal.uahComponentAmount, 8400);

      final premium = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[2], // White
        crown: ServiceCatalog.crownTiers[2], // prem
        implantCount: 1,
        crownUnits: 1,
      );
      expect(premium.eurAmount, 2400);
      expect(premium.uahComponentAmount, 8400);
    });

    test('Чернівці: rational/optimal/premium match the ТЗ table', () {
      final rational = engine.unitScenario(
        city: ServiceCity.chernivtsi,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 1,
        crownUnits: 1,
      );
      expect(rational.eurAmount, 780);
      expect(rational.uahComponentAmount, 6900);

      final optimal = engine.unitScenario(
        city: ServiceCity.chernivtsi,
        implant: ServiceCatalog.singleToothImplantTiers[1],
        crown: ServiceCatalog.crownTiers[1],
        implantCount: 1,
        crownUnits: 1,
      );
      expect(optimal.eurAmount, 1280);
      expect(optimal.uahComponentAmount, 7900);

      final premium = engine.unitScenario(
        city: ServiceCity.chernivtsi,
        implant: ServiceCatalog.singleToothImplantTiers[2],
        crown: ServiceCatalog.crownTiers[2],
        implantCount: 1,
        crownUnits: 1,
      );
      expect(premium.eurAmount, 1900);
      expect(premium.uahComponentAmount, 7900);
    });

    test('changing CV crown price never touches IF pricing (ТЗ §9)', () {
      expect(
        ServiceCatalog.crownBase.priceFor(ServiceCity.ivanoFrankivsk)!.amount,
        300,
      );
      expect(
        ServiceCatalog.crownBase.priceFor(ServiceCity.chernivtsi)!.amount,
        200,
      );
    });
  });

  group('bridges — ТЗ §4.4 acceptance criteria', () {
    test('two implants multiply implant/healing/supra/crown by 2, scan by 1', () {
      final one = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 1,
        crownUnits: 1,
      );
      final two = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 2,
        crownUnits: 2,
      );
      // implant+supra (eur) and healing (uah) double; scan (part of uah) stays flat.
      expect(two.eurAmount, one.eurAmount * 2);
      final scan = ServiceCatalog.scanBoth
          .priceFor(ServiceCity.ivanoFrankivsk)!
          .amount;
      expect(
        two.uahComponentAmount,
        (one.uahComponentAmount - scan) * 2 + scan,
      );
    });

    test('three adjacent teeth = 2 implants + 3 crown units', () {
      expect(adjacentBridgeCounts(3), (2, 3));
    });

    test('temp crown adds extra abutment, temp crown units, one rescan', () {
      final without = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 1,
        crownUnits: 1,
      );
      final withTemp = engine.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 1,
        crownUnits: 1,
        tempCrown: true,
      );
      expect(withTemp.eurAmount, without.eurAmount + 50); // std extra abutment
      expect(
        withTemp.uahComponentAmount,
        without.uahComponentAmount + 2100 + 3400,
      );
    });
  });

  group('All-on-N — ТЗ §4.6 acceptance criteria', () {
    test('All-on-6 = 6 implants + 6 multiunits + one temp + one final arch', () {
      final r = engine.allOnScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.fullArchImplantTiers[0], // Neodent
        archFinal: ServiceCatalog.archFinalTiers[0], // base
        implantsPerJaw: 6,
      );
      final expectedFirstStage = 6 * 480 + 6 * 65 + 1000.0;
      expect(r.archFirstStageEur, expectedFirstStage);
      expect(r.archFirstStageUah, 3400);
      expect(r.archFullEur, expectedFirstStage + 2900);
      expect(r.archFullUah, 6800);
    });

    test('both jaws double EUR components but scan stays a single record', () {
      final oneJaw = engine.allOnScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.fullArchImplantTiers[0],
        archFinal: ServiceCatalog.archFinalTiers[0],
        implantsPerJaw: 6,
      );
      final bothJaws = engine.allOnScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.fullArchImplantTiers[0],
        archFinal: ServiceCatalog.archFinalTiers[0],
        implantsPerJaw: 6,
        bothJaws: true,
      );
      expect(bothJaws.archFullEur, oneJaw.archFullEur * 2);
      expect(bothJaws.archFullUah, oneJaw.archFullUah); // still 6800, not doubled
    });
  });

  group('tier comparison cards — ТЗ §6.1 "поточна / дешевша / дорожча"', () {
    test('unitCombos returns the current combo plus its price neighbours', () {
      final combos = engine.unitCombos(
        city: ServiceCity.ivanoFrankivsk,
        implantTiers: ServiceCatalog.singleToothImplantTiers,
        implantCount: 1,
        crownUnits: 1,
        currentImplantIndex: 1, // Straumann
        currentCrownIndex: 1, // opt
      );
      expect(combos.where((c) => c.isCurrent), hasLength(1));
      expect(combos.length, lessThanOrEqualTo(3));
      final sorted = [...combos]..sort((a, b) => a.eurTotal.compareTo(b.eurTotal));
      expect(combos, orderedEquals(sorted));
    });

    test('the rational tier (cheapest) has no cheaper neighbour', () {
      final combos = engine.unitCombos(
        city: ServiceCity.ivanoFrankivsk,
        implantTiers: ServiceCatalog.singleToothImplantTiers,
        implantCount: 1,
        crownUnits: 1,
        currentImplantIndex: 0,
        currentCrownIndex: 0,
      );
      final current = combos.firstWhere((c) => c.isCurrent);
      expect(combos.every((c) => c.eurTotal >= current.eurTotal), isTrue);
    });
  });

  group('currency conversion — ТЗ §4.1 / §9', () {
    test('changing the NBU rate only changes the UAH equivalent', () {
      const cheapRate = PricingEngine(nbuEurRate: 40);
      const expensiveRate = PricingEngine(nbuEurRate: 50);
      final cheap = cheapRate.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 1,
        crownUnits: 1,
      );
      final expensive = expensiveRate.unitScenario(
        city: ServiceCity.ivanoFrankivsk,
        implant: ServiceCatalog.singleToothImplantTiers[0],
        crown: ServiceCatalog.crownTiers[0],
        implantCount: 1,
        crownUnits: 1,
      );
      expect(cheap.eurAmount, expensive.eurAmount);
      expect(cheap.uahEquivalentTotal, isNot(expensive.uahEquivalentTotal));
    });
  });

  group('scenario resolver — ТЗ §5 dead-ends', () {
    test('replacing an implant/crown is an individual-only dead end', () {
      final spec = resolveScenario({'a1': 'replace_implant_or_crown'});
      expect(spec.kind, ScenarioKind.individual);
    });

    test('existing full-jaw construction is an individual-only dead end', () {
      final spec = resolveScenario({
        'e1': 'existing_implant_construction',
      });
      expect(spec.kind, ScenarioKind.individual);
    });

    test('"не знаю" with no branch reached falls back to a rough estimate', () {
      expect(isRoughEstimateOnly({}), isTrue);
    });
  });
}
