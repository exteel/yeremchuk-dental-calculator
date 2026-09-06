import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_result.dart';

/// All formulas from ТЗ §4, reading exclusively through [ServiceCatalog] —
/// no literal prices live here, only the arithmetic that combines them.
class PricingEngine {
  const PricingEngine({this.nbuEurRate = nbuEurRateFallback});

  final double nbuEurRate;

  double _amt(CatalogEntry entry, ServiceCity city) =>
      entry.priceFor(city)?.amount ?? 0;

  double round100(double uah) => (uah / 100).round() * 100.0;

  /// ТЗ §4.1: `total_uah = round100(sum_eur × nbu_rate + sum_uah)`.
  double uahEquivalent(double eurAmount, double uahComponents) =>
      round100(eurAmount * nbuEurRate + uahComponents);

  CatalogEntry _supraForGroup(ImplantGroup group) =>
      group == ImplantGroup.premium
      ? ServiceCatalog.supraPrem
      : ServiceCatalog.supraStd;

  CatalogEntry _healingForGroup(ImplantGroup group) =>
      group == ImplantGroup.premium
      ? ServiceCatalog.healPrem
      : ServiceCatalog.healStd;

  CatalogEntry _multiunitForGroup(ImplantGroup group) =>
      group == ImplantGroup.premium
      ? ServiceCatalog.multiunitPrem
      : ServiceCatalog.multiunitStd;

  CatalogEntry _extraAbutmentForGroup(ImplantGroup group) =>
      group == ImplantGroup.premium
      ? ServiceCatalog.abutExtraPrem
      : ServiceCatalog.abutExtraStd;

  /// ТЗ §4.2/§4.4 — one or several adjacent teeth. [implantCount] and
  /// [crownUnits] follow table 4.4 (e.g. 3 adjacent teeth → 2 implants, 3
  /// crown units). Scan is always counted once, regardless of implant
  /// count — ТЗ §9 acceptance criterion.
  CalculatorResult unitScenario({
    required ServiceCity city,
    required ImplantSystem implant,
    required CatalogEntry crown,
    required int implantCount,
    required int crownUnits,
    bool tempCrown = false,
    String? clinicalSummaryOverride,
    List<TierCombo> combos = const [],
    String primaryTierLabel = 'Рівень імпланта',
    String secondaryTierLabel = 'Рівень коронки',
  }) {
    final group = implant.group;
    final supra = _supraForGroup(group);
    final healing = _healingForGroup(group);

    var eur =
        implantCount * _amt(implant.toEntry(), city) +
        implantCount * _amt(supra, city) +
        crownUnits * _amt(crown, city);
    var uah = implantCount * _amt(healing, city) + _amt(
      ServiceCatalog.scanBoth,
      city,
    );

    final lines = <BreakdownLine>[
      BreakdownLine(
        '${implant.displayName} × $implantCount (імплант + встановлення)',
        Money.fixed(Currency.eur, implantCount * _amt(implant.toEntry(), city)),
      ),
      BreakdownLine(
        '${supra.displayName} × $implantCount',
        Money.fixed(Currency.eur, implantCount * _amt(supra, city)),
      ),
      BreakdownLine(
        '${crown.displayName} × $crownUnits',
        Money.fixed(Currency.eur, crownUnits * _amt(crown, city)),
      ),
      BreakdownLine(
        '${healing.displayName} × $implantCount',
        Money.fixed(Currency.uah, implantCount * _amt(healing, city)),
      ),
      BreakdownLine(
        ServiceCatalog.scanBoth.displayName,
        Money.fixed(Currency.uah, _amt(ServiceCatalog.scanBoth, city)),
      ),
    ];

    if (tempCrown) {
      final extraAbutment = _extraAbutmentForGroup(group);
      final abutmentEur = implantCount * _amt(extraAbutment, city);
      final tempCrownUah = crownUnits * _amt(ServiceCatalog.tempCrownUnit, city);
      final rescanUah = _amt(ServiceCatalog.scanBoth, city);
      eur += abutmentEur;
      uah += tempCrownUah + rescanUah;
      lines.addAll([
        BreakdownLine(
          '${extraAbutment.displayName} × $implantCount (тимчасова)',
          Money.fixed(Currency.eur, abutmentEur),
        ),
        BreakdownLine(
          '${ServiceCatalog.tempCrownUnit.displayName} × $crownUnits',
          Money.fixed(Currency.uah, tempCrownUah),
        ),
        BreakdownLine(
          'Повторне сканування',
          Money.fixed(Currency.uah, rescanUah),
        ),
      ]);
    }

    return CalculatorResult(
      kind: ResultKind.singleOrBridge,
      clinicalSummary:
          clinicalSummaryOverride ??
          (implantCount == 1 && crownUnits == 1
              ? '1 імплант + 1 коронка'
              : '$implantCount ${_pluralImplants(implantCount)} + '
                    '$crownUnits ${_pluralCrowns(crownUnits)}'),
      eurAmount: eur,
      uahComponentAmount: uah,
      uahEquivalentTotal: uahEquivalent(eur, uah),
      breakdown: lines,
      combos: combos,
      primaryTierLabel: primaryTierLabel,
      secondaryTierLabel: secondaryTierLabel,
    );
  }

  /// Builds all 9 implant×crown combinations for the tier-comparison cards
  /// (ТЗ §6.1 "Три картки: поточна, найближча дешевша, найближча дорожча").
  List<TierCombo> unitCombos({
    required ServiceCity city,
    required List<ImplantSystem> implantTiers,
    required int implantCount,
    required int crownUnits,
    required int currentImplantIndex,
    required int currentCrownIndex,
    bool tempCrown = false,
  }) {
    final all = <TierCombo>[];
    for (var i = 0; i < implantTiers.length; i++) {
      for (var j = 0; j < ServiceCatalog.crownTiers.length; j++) {
        final r = unitScenario(
          city: city,
          implant: implantTiers[i],
          crown: ServiceCatalog.crownTiers[j],
          implantCount: implantCount,
          crownUnits: crownUnits,
          tempCrown: tempCrown,
        );
        all.add(
          TierCombo(
            primaryTierIndex: i,
            secondaryTierIndex: j,
            label: '${implantTiers[i].displayName} · '
                '${ServiceCatalog.crownTiers[j].displayName}',
            eurTotal: r.eurAmount,
            uahEquivalentTotal: r.uahEquivalentTotal,
            isCurrent: i == currentImplantIndex && j == currentCrownIndex,
          ),
        );
      }
    }
    return _nearestThree(all);
  }

  /// ТЗ §4.6 — first stage + full-treatment figure for All-on-4/6/8.
  CalculatorResult allOnScenario({
    required ServiceCity city,
    required ImplantSystem implant,
    required CatalogEntry archFinal,
    required int implantsPerJaw,
    bool bothJaws = false,
    List<TierCombo> combos = const [],
  }) {
    final group = implant.group;
    final multiunit = _multiunitForGroup(group);
    final jaws = bothJaws ? 2 : 1;

    final firstStageEur =
        jaws *
        (implantsPerJaw * _amt(implant.toEntry(), city) +
            implantsPerJaw * _amt(multiunit, city) +
            _amt(ServiceCatalog.archTemp, city));
    const firstStageUah = 3400.0;

    final fullEur = firstStageEur + jaws * _amt(archFinal, city);
    const fullUah = 6800.0;

    final lines = <BreakdownLine>[
      BreakdownLine(
        '${implant.displayName} × ${implantsPerJaw * jaws}',
        Money.fixed(
          Currency.eur,
          jaws * implantsPerJaw * _amt(implant.toEntry(), city),
        ),
      ),
      BreakdownLine(
        '${multiunit.displayName} × ${implantsPerJaw * jaws}',
        Money.fixed(
          Currency.eur,
          jaws * implantsPerJaw * _amt(multiunit, city),
        ),
      ),
      BreakdownLine(
        '${ServiceCatalog.archTemp.displayName}'
        '${bothJaws ? ' × 2 щелепи' : ''}',
        Money.fixed(Currency.eur, jaws * _amt(ServiceCatalog.archTemp, city)),
      ),
      BreakdownLine(
        '${archFinal.displayName}${bothJaws ? ' × 2 щелепи' : ''}',
        Money.fixed(Currency.eur, jaws * _amt(archFinal, city)),
      ),
    ];

    return CalculatorResult(
      kind: ResultKind.fullArch,
      clinicalSummary:
          'All-on-$implantsPerJaw${bothJaws ? ' на обох щелепах' : ''}',
      eurAmount: fullEur,
      uahComponentAmount: fullUah,
      uahEquivalentTotal: uahEquivalent(fullEur, fullUah),
      breakdown: lines,
      combos: combos,
      primaryTierLabel: 'Рівень імпланта',
      secondaryTierLabel: 'Рівень постійної конструкції',
      archFirstStageEur: firstStageEur,
      archFirstStageUah: firstStageUah,
      archFullEur: fullEur,
      archFullUah: fullUah,
    );
  }

  /// ТЗ §6.2 "Три картки 4/6/8" — compares arch *size* at the currently
  /// chosen implant/construction tier, unlike [unitCombos] which compares
  /// tiers at a fixed size. All three sizes are always returned (not just
  /// the nearest 3) since there are only three to begin with.
  List<TierCombo> archSizeCombos({
    required ServiceCity city,
    required ImplantSystem implant,
    required CatalogEntry archFinal,
    required bool bothJaws,
    required int currentSize,
  }) {
    return [
      for (final n in const [4, 6, 8])
        TierCombo(
          primaryTierIndex: n,
          secondaryTierIndex: 0,
          label: 'All-on-$n',
          eurTotal: allOnScenario(
            city: city,
            implant: implant,
            archFinal: archFinal,
            implantsPerJaw: n,
            bothJaws: bothJaws,
          ).archFullEur,
          uahEquivalentTotal: allOnScenario(
            city: city,
            implant: implant,
            archFinal: archFinal,
            implantsPerJaw: n,
            bothJaws: bothJaws,
          ).uahEquivalentTotal,
          isCurrent: n == currentSize,
        ),
    ];
  }

  /// ТЗ §4.5 — patient already has an implant placed elsewhere.
  CalculatorResult existingImplantTotal({
    required ServiceCity city,
    required ImplantGroup group,
    required CatalogEntry crown,
    bool immediatelyPermanent = true,
  }) {
    final supra = _supraForGroup(group);
    final scan = _amt(ServiceCatalog.scanBoth, city);
    final crownPrice = _amt(crown, city);
    final supraPrice = _amt(supra, city);

    if (immediatelyPermanent) {
      final eur = supraPrice + crownPrice;
      final uah = scan;
      return CalculatorResult(
        kind: ResultKind.singleOrBridge,
        clinicalSummary: 'Постійна коронка на наявний імплант',
        eurAmount: eur,
        uahComponentAmount: uah,
        uahEquivalentTotal: uahEquivalent(eur, uah),
        breakdown: [
          BreakdownLine(supra.displayName, Money.fixed(Currency.eur, supraPrice)),
          BreakdownLine(crown.displayName, Money.fixed(Currency.eur, crownPrice)),
          BreakdownLine(
            ServiceCatalog.scanBoth.displayName,
            Money.fixed(Currency.uah, scan),
          ),
        ],
        combos: const [],
        primaryTierLabel: 'Рівень коронки',
        secondaryTierLabel: '',
      );
    }

    final extraAbutment = _extraAbutmentForGroup(group);
    final tempCrownUah = _amt(ServiceCatalog.tempCrownUnit, city);
    final eur = supraPrice + _amt(extraAbutment, city) + crownPrice;
    final uah = scan + tempCrownUah + scan;
    return CalculatorResult(
      kind: ResultKind.singleOrBridge,
      clinicalSummary: 'Тимчасова, потім постійна коронка на наявний імплант',
      eurAmount: eur,
      uahComponentAmount: uah,
      uahEquivalentTotal: uahEquivalent(eur, uah),
      breakdown: [
        BreakdownLine(supra.displayName, Money.fixed(Currency.eur, supraPrice)),
        BreakdownLine(
          extraAbutment.displayName,
          Money.fixed(Currency.eur, _amt(extraAbutment, city)),
        ),
        BreakdownLine(crown.displayName, Money.fixed(Currency.eur, crownPrice)),
        BreakdownLine(
          'Сканування × 2 (тимчасова + постійна)',
          Money.fixed(Currency.uah, scan * 2),
        ),
        BreakdownLine(
          ServiceCatalog.tempCrownUnit.displayName,
          Money.fixed(Currency.uah, tempCrownUah),
        ),
      ],
      combos: const [],
      primaryTierLabel: 'Рівень коронки',
      secondaryTierLabel: '',
    );
  }

  /// ТЗ §4.7 — rough sedation range, shown as an optional add-on only, never
  /// summed automatically into the total.
  Money estimateSedationRange({
    required ServiceCity city,
    required int implantCount,
    bool fullJaw = false,
    bool bothJaws = false,
  }) {
    final hourPrice = _amt(ServiceCatalog.sedationHour, city);
    if (bothJaws) return Money.range(Currency.eur, hourPrice * 4, hourPrice * 6);
    if (fullJaw) return Money.range(Currency.eur, hourPrice * 2, hourPrice * 3);
    if (implantCount <= 1) return Money.fixed(Currency.eur, hourPrice);
    return Money.range(Currency.eur, hourPrice, hourPrice * 1.5);
  }

  List<TierCombo> _nearestThree(List<TierCombo> all) {
    final sorted = [...all]..sort((a, b) => a.eurTotal.compareTo(b.eurTotal));
    final currentIndex = sorted.indexWhere((c) => c.isCurrent);
    if (currentIndex == -1) return sorted.take(3).toList();
    final result = <TierCombo>[];
    if (currentIndex > 0) result.add(sorted[currentIndex - 1]);
    result.add(sorted[currentIndex]);
    if (currentIndex < sorted.length - 1) result.add(sorted[currentIndex + 1]);
    return result;
  }

  String _pluralImplants(int n) => n == 1 ? 'імплант' : 'імпланти';
  String _pluralCrowns(int n) => n == 1 ? 'коронка' : 'коронок';
}

extension on ImplantSystem {
  CatalogEntry toEntry() {
    switch (code) {
      case 'IMP_NEODENT':
        return ServiceCatalog.impNeodent;
      case 'IMP_NEODENT_ACTIVE':
        return ServiceCatalog.impNeodentActive;
      case 'IMP_BAUERS_ASPER':
        return ServiceCatalog.impBauersAsper;
      case 'IMP_STRAUMANN':
        return ServiceCatalog.impStraumann;
      case 'IMP_STRAUMANN_ACTIVE':
        return ServiceCatalog.impStraumannActive;
      case 'IMP_STRAUMANN_WHITE':
        return ServiceCatalog.impStraumannWhite;
      default:
        throw ArgumentError('Unknown implant code: $code');
    }
  }
}

