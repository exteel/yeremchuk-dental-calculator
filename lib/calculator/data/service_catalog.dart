/// Single source of truth for calculator pricing (ТЗ §2). In production this
/// would be read from a CMS-backed API — the page and the calculator must
/// never each hardcode their own copy of a price. Until that backend exists,
/// [ServiceCatalog] is the one static place these numbers live; every
/// formula in `pricing_engine.dart` reads through it by [service_code],
/// never a literal number.
library;

enum ServiceCity { ivanoFrankivsk, chernivtsi }

extension ServiceCityLabel on ServiceCity {
  String get label => switch (this) {
    ServiceCity.ivanoFrankivsk => 'Івано-Франківськ',
    ServiceCity.chernivtsi => 'Чернівці',
  };

  String get shortCode => switch (this) {
    ServiceCity.ivanoFrankivsk => 'IF',
    ServiceCity.chernivtsi => 'CV',
  };
}

enum Currency { eur, uah }

/// A fixed amount or a min–max range, in one currency (ТЗ §2 `price` /
/// `min_price` / `max_price`).
class Money {
  const Money.fixed(this.currency, double amount)
    : minAmount = amount,
      maxAmount = amount;

  const Money.range(this.currency, this.minAmount, this.maxAmount);

  final Currency currency;
  final double minAmount;
  final double maxAmount;

  bool get isRange => minAmount != maxAmount;
  double get amount => minAmount;

  Money operator *(num factor) =>
      Money.range(currency, minAmount * factor, maxAmount * factor);

  Money operator +(Money other) {
    assert(currency == other.currency, 'Cannot add different currencies');
    return Money.range(
      currency,
      minAmount + other.minAmount,
      maxAmount + other.maxAmount,
    );
  }

  static Money zero(Currency currency) => Money.fixed(currency, 0);
}

/// The price-group an implant system belongs to (ТЗ §3.3) — determines which
/// healing-cap / multi-unit / extra-abutment price applies. A pricing
/// grouping only, not a claim about component compatibility.
enum ImplantGroup { standard, premium }

/// Which role a catalog entry plays in a formula (ТЗ §2 `calculator_role`).
enum CalculatorRole {
  implant,
  healing,
  scan,
  superstructure,
  crown,
  multiunit,
  archTemp,
  archFinal,
  addon,
}

class CatalogEntry {
  const CatalogEntry({
    required this.serviceCode,
    required this.displayName,
    required this.calculatorRole,
    required this.pricesByCity,
    this.active = true,
    this.includedText,
  });

  final String serviceCode;
  final String displayName;
  final CalculatorRole calculatorRole;

  /// Missing city key = not offered there (e.g. `IMP_BAUERS_ASPER` is CV
  /// only). `ServiceCity`-keyed rather than `shared` per ТЗ §2's `city`
  /// field, since every entry in this catalog does vary or could vary by
  /// city even when today's numbers happen to match.
  final Map<ServiceCity, Money> pricesByCity;
  final bool active;
  final String? includedText;

  Money? priceFor(ServiceCity city) => active ? pricesByCity[city] : null;
}

/// An implant system: catalog entry + price tier + pricing group.
class ImplantSystem {
  const ImplantSystem(this.code, this.displayName, this.group);

  final String code;
  final String displayName;
  final ImplantGroup group;
}

abstract class ServiceCatalog {
  static const _if = ServiceCity.ivanoFrankivsk;
  static const _cv = ServiceCity.chernivtsi;

  // ---- 3.1 Діагностика --------------------------------------------------
  static const consultImplant = CatalogEntry(
    serviceCode: 'CONSULT_IMPLANT',
    displayName: 'Консультація імплантолога',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 600),
      _cv: Money.fixed(Currency.uah, 550),
    },
  );

  static const scanBoth = CatalogEntry(
    serviceCode: 'SCAN_BOTH',
    displayName: 'Сканування обох щелеп',
    calculatorRole: CalculatorRole.scan,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 3400),
      _cv: Money.fixed(Currency.uah, 3400),
    },
  );

  // ---- 3.2 Імпланти зі встановленням -------------------------------------
  static const impNeodent = CatalogEntry(
    serviceCode: 'IMP_NEODENT',
    displayName: 'Neodent',
    calculatorRole: CalculatorRole.implant,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 480),
      _cv: Money.fixed(Currency.eur, 480),
    },
    includedText: 'Імплант, встановлення та місцева анестезія',
  );

  static const impNeodentActive = CatalogEntry(
    serviceCode: 'IMP_NEODENT_ACTIVE',
    displayName: 'Neodent Active',
    calculatorRole: CalculatorRole.implant,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 550),
      _cv: Money.fixed(Currency.eur, 550),
    },
  );

  static const impBauersAsper = CatalogEntry(
    serviceCode: 'IMP_BAUERS_ASPER',
    displayName: 'Bauers Asper',
    calculatorRole: CalculatorRole.implant,
    pricesByCity: {_cv: Money.fixed(Currency.eur, 650)},
  );

  static const impStraumann = CatalogEntry(
    serviceCode: 'IMP_STRAUMANN',
    displayName: 'Straumann',
    calculatorRole: CalculatorRole.implant,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 780),
      _cv: Money.fixed(Currency.eur, 780),
    },
  );

  static const impStraumannActive = CatalogEntry(
    serviceCode: 'IMP_STRAUMANN_ACTIVE',
    displayName: 'Straumann SLA Active',
    calculatorRole: CalculatorRole.implant,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 850),
      _cv: Money.fixed(Currency.eur, 850),
    },
  );

  static const impStraumannWhite = CatalogEntry(
    serviceCode: 'IMP_STRAUMANN_WHITE',
    displayName: 'Straumann White',
    calculatorRole: CalculatorRole.implant,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 1200),
      _cv: Money.fixed(Currency.eur, 1200),
    },
  );

  /// ТЗ §3.3: pricing group per implant system.
  static const Map<String, ImplantGroup> implantGroupByCode = {
    'IMP_NEODENT': ImplantGroup.standard,
    'IMP_NEODENT_ACTIVE': ImplantGroup.standard,
    'IMP_BAUERS_ASPER': ImplantGroup.standard,
    'IMP_STRAUMANN': ImplantGroup.premium,
    'IMP_STRAUMANN_ACTIVE': ImplantGroup.premium,
    'IMP_STRAUMANN_WHITE': ImplantGroup.premium,
  };

  /// Per-scenario implant tiers (ТЗ §5.10): single/multi-tooth vs full-jaw
  /// use a different "preміальний" system.
  static const singleToothImplantTiers = [
    ImplantSystem('IMP_NEODENT', 'Neodent', ImplantGroup.standard),
    ImplantSystem('IMP_STRAUMANN', 'Straumann', ImplantGroup.premium),
    ImplantSystem(
      'IMP_STRAUMANN_WHITE',
      'Straumann White',
      ImplantGroup.premium,
    ),
  ];

  static const fullArchImplantTiers = [
    ImplantSystem('IMP_NEODENT', 'Neodent', ImplantGroup.standard),
    ImplantSystem('IMP_STRAUMANN', 'Straumann', ImplantGroup.premium),
    ImplantSystem(
      'IMP_STRAUMANN_ACTIVE',
      'Straumann SLA Active',
      ImplantGroup.premium,
    ),
  ];

  // ---- 3.3 Формувачі та компоненти --------------------------------------
  static const healStd = CatalogEntry(
    serviceCode: 'HEAL_STD',
    displayName: 'Формувач: Neodent-група',
    calculatorRole: CalculatorRole.healing,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 3500),
      _cv: Money.fixed(Currency.uah, 3500),
    },
  );

  static const healPrem = CatalogEntry(
    serviceCode: 'HEAL_PREM',
    displayName: 'Формувач: Straumann-група',
    calculatorRole: CalculatorRole.healing,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 5000),
      _cv: Money.fixed(Currency.uah, 4500),
    },
  );

  static const supraStd = CatalogEntry(
    serviceCode: 'SUPRA_STD',
    displayName: 'Комплект супраструктур: стандарт',
    calculatorRole: CalculatorRole.superstructure,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 100),
      _cv: Money.fixed(Currency.eur, 100),
    },
  );

  static const supraPrem = CatalogEntry(
    serviceCode: 'SUPRA_PREM',
    displayName: 'Комплект супраструктур: преміум',
    calculatorRole: CalculatorRole.superstructure,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 200),
      _cv: Money.fixed(Currency.eur, 200),
    },
  );

  static const abutExtraStd = CatalogEntry(
    serviceCode: 'ABUT_EXTRA_STD',
    displayName: 'Додатковий абатмент: стандарт',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 50),
      _cv: Money.fixed(Currency.eur, 50),
    },
  );

  static const abutExtraPrem = CatalogEntry(
    serviceCode: 'ABUT_EXTRA_PREM',
    displayName: 'Додатковий абатмент: преміум',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 100),
      _cv: Money.fixed(Currency.eur, 100),
    },
  );

  static const multiunitStd = CatalogEntry(
    serviceCode: 'MULTIUNIT_STD',
    displayName: 'Мультиюніт: Neodent-група',
    calculatorRole: CalculatorRole.multiunit,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 65),
      _cv: Money.fixed(Currency.eur, 65),
    },
  );

  static const multiunitPrem = CatalogEntry(
    serviceCode: 'MULTIUNIT_PREM',
    displayName: 'Мультиюніт: Straumann-група',
    calculatorRole: CalculatorRole.multiunit,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 118),
      _cv: Money.fixed(Currency.eur, 118),
    },
  );

  // ---- 3.4 Коронки --------------------------------------------------------
  static const crownBase = CatalogEntry(
    serviceCode: 'CROWN_BASE',
    displayName: 'Монолітний цирконій без індивідуального нанесення',
    calculatorRole: CalculatorRole.crown,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 300),
      _cv: Money.fixed(Currency.eur, 200),
    },
  );

  static const crownOpt = CatalogEntry(
    serviceCode: 'CROWN_OPT',
    displayName: 'Багатошаровий монолітний цирконій',
    calculatorRole: CalculatorRole.crown,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 500),
      _cv: Money.fixed(Currency.eur, 300),
    },
  );

  static const crownPrem = CatalogEntry(
    serviceCode: 'CROWN_PREM',
    displayName: 'Цирконій з індивідуальним нанесенням',
    calculatorRole: CalculatorRole.crown,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 1000),
      _cv: Money.fixed(Currency.eur, 500),
    },
  );

  static const tempCrownUnit = CatalogEntry(
    serviceCode: 'TEMP_CROWN_UNIT',
    displayName: 'Тимчасова коронка/одиниця моста',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 2100),
      _cv: Money.fixed(Currency.uah, 2100),
    },
  );

  static const crownTiers = [crownBase, crownOpt, crownPrem];

  // ---- 3.5 Видалення та допоміжні позиції (не входять у формулу автоматично)
  static const extractSimple = CatalogEntry(
    serviceCode: 'EXTRACT_SIMPLE',
    displayName: 'Просте видалення',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 1650),
      _cv: Money.fixed(Currency.uah, 1650),
    },
  );

  static const extractComplex = CatalogEntry(
    serviceCode: 'EXTRACT_COMPLEX',
    displayName: 'Складне видалення',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 2900),
      _cv: Money.fixed(Currency.uah, 2900),
    },
  );

  static const crownRemoveScrew = CatalogEntry(
    serviceCode: 'CROWN_REMOVE_SCREW',
    displayName: 'Зняття гвинтової коронки',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 0),
      _cv: Money.fixed(Currency.uah, 0),
    },
  );

  static const crownRemoveCement = CatalogEntry(
    serviceCode: 'CROWN_REMOVE_CEMENT',
    displayName: 'Зняття цементної коронки',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.uah, 900),
      _cv: Money.fixed(Currency.uah, 900),
    },
  );

  // ---- 3.6 Повна щелепа й додаткові процедури ----------------------------
  static const archTemp = CatalogEntry(
    serviceCode: 'ARCH_TEMP',
    displayName: 'Тимчасова пластмасова конструкція на металевому каркасі',
    calculatorRole: CalculatorRole.archTemp,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 1000),
      _cv: Money.fixed(Currency.eur, 1000),
    },
  );

  static const archFinalBase = CatalogEntry(
    serviceCode: 'ARCH_FINAL_BASE',
    displayName: 'Металокерамічна постійна конструкція',
    calculatorRole: CalculatorRole.archFinal,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 2900),
      _cv: Money.fixed(Currency.eur, 2900),
    },
  );

  static const archFinalOpt = CatalogEntry(
    serviceCode: 'ARCH_FINAL_OPT',
    displayName: 'Цирконій на фрезерованій титановій балці',
    calculatorRole: CalculatorRole.archFinal,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 4900),
      _cv: Money.fixed(Currency.eur, 4900),
    },
  );

  static const archFinalPrem = CatalogEntry(
    serviceCode: 'ARCH_FINAL_PREM',
    displayName: 'Преміальний цирконій на титановій балці',
    calculatorRole: CalculatorRole.archFinal,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 7800),
      _cv: Money.fixed(Currency.eur, 7800),
    },
  );

  static const archFinalTiers = [archFinalBase, archFinalOpt, archFinalPrem];

  static const sedationHour = CatalogEntry(
    serviceCode: 'SEDATION_HOUR',
    displayName: 'Седація',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 100),
      _cv: Money.fixed(Currency.eur, 100),
    },
  );

  static const augmentSegment = CatalogEntry(
    serviceCode: 'AUGMENT_SEGMENT',
    displayName: 'Кісткова аугментація з матеріалами',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 1000),
      _cv: Money.fixed(Currency.eur, 1000),
    },
  );

  static const sinusLift = CatalogEntry(
    serviceCode: 'SINUS_LIFT',
    displayName: 'Синус-ліфтинг з матеріалами',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.fixed(Currency.eur, 1000),
      _cv: Money.fixed(Currency.eur, 1000),
    },
  );

  static const softTissue = CatalogEntry(
    serviceCode: 'SOFT_TISSUE',
    displayName: 'Пластика м’яких тканин',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.range(Currency.eur, 300, 350),
      _cv: Money.range(Currency.eur, 300, 350),
    },
  );

  static const guideClassic = CatalogEntry(
    serviceCode: 'GUIDE_CLASSIC',
    displayName: 'Нерозбірний навігаційний шаблон',
    calculatorRole: CalculatorRole.addon,
    pricesByCity: {
      _if: Money.range(Currency.eur, 250, 350),
      _cv: Money.range(Currency.eur, 250, 350),
    },
  );

  /// The "не входять автоматично" extras patients can ask about (ТЗ §3.6,
  /// §4.7, §10) — shown as informational chips, never summed into a total.
  static const notAutoIncluded = [
    extractSimple,
    extractComplex,
    augmentSegment,
    sinusLift,
    softTissue,
    guideClassic,
    sedationHour,
  ];

  ImplantGroup groupOf(String implantCode) =>
      implantGroupByCode[implantCode] ?? ImplantGroup.standard;

  static const healingByGroup = {
    ImplantGroup.standard: healStd,
    ImplantGroup.premium: healPrem,
  };

  static const multiunitByGroup = {
    ImplantGroup.standard: multiunitStd,
    ImplantGroup.premium: multiunitPrem,
  };

  static const extraAbutmentByGroup = {
    ImplantGroup.standard: abutExtraStd,
    ImplantGroup.premium: abutExtraPrem,
  };

  static ImplantGroup groupForCode(String implantCode) =>
      implantGroupByCode[implantCode] ?? ImplantGroup.standard;
}

/// Placeholder NBU EUR→UAH rate (ТЗ §4.1). A real implementation reads this
/// daily from the NBU exchange-rate API; wire that in before launch — using
/// a stale hardcoded rate here would silently misprice every EUR-denominated
/// line the moment the real rate moves.
const double nbuEurRateFallback = 45.0;
