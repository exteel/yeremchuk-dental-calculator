import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_result.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';
import 'package:yeremchuk_dental_calculator/theme/app_spacing.dart';

String _formatNumber(double v) {
  final digits = v.round().abs().toString();
  final buffer = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _formatEur(double v) => '${_formatNumber(v)} €';
String _formatUah(double v) => '${_formatNumber(v)} грн';

String _formatMoney(Money m) {
  final unit = m.currency == Currency.eur ? '€' : 'грн';
  if (m.isRange) {
    return '${_formatNumber(m.minAmount)}–${_formatNumber(m.maxAmount)} $unit';
  }
  return '${_formatNumber(m.amount)} $unit';
}

/// Ukrainian numbers are 10 digits (0XXXXXXXXX) or 12 with the country code;
/// anything shorter can't be called back.
bool isValidPhone(String input) =>
    input.replaceAll(RegExp(r'\D'), '').length >= 10;

final _phoneInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9+\-\s()]'),
);

/// ТЗ §6 — the teaser/result screen. Renders the same widget before and
/// after the phone gate: tier toggles work either way (ТЗ §4.2 "До
/// контакту пацієнт окремо вибирає рівень імпланта й коронки"), but no sum
/// is shown anywhere until [phoneSubmitted].
class CalculatorResultView extends StatefulWidget {
  const CalculatorResultView({
    required this.result,
    required this.city,
    required this.archSize,
    required this.primaryTierIndex,
    required this.secondaryTierIndex,
    required this.tempCrownRequested,
    required this.phoneSubmitted,
    required this.consultationSubmitting,
    required this.consultationRequested,
    required this.canGoBack,
    required this.onBack,
    required this.onCityChanged,
    required this.onPrimaryTierChanged,
    required this.onSecondaryTierChanged,
    required this.onArchSizeChanged,
    required this.onTempCrownChanged,
    required this.onSubmitPhone,
    required this.onRequestConsultation,
    super.key,
  });

  final CalculatorResult result;
  final ServiceCity city;
  final int archSize;
  final int primaryTierIndex;
  final int secondaryTierIndex;
  final bool tempCrownRequested;
  final bool phoneSubmitted;
  final bool consultationSubmitting;
  final bool consultationRequested;
  final bool canGoBack;
  final VoidCallback onBack;
  final ValueChanged<ServiceCity> onCityChanged;
  final ValueChanged<int> onPrimaryTierChanged;
  final ValueChanged<int> onSecondaryTierChanged;
  final ValueChanged<int> onArchSizeChanged;
  final ValueChanged<bool> onTempCrownChanged;
  final ValueChanged<String> onSubmitPhone;
  final VoidCallback onRequestConsultation;

  @override
  State<CalculatorResultView> createState() => _CalculatorResultViewState();
}

class _CalculatorResultViewState extends State<CalculatorResultView> {
  final _phoneController = TextEditingController();
  bool _consent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _setConsent(bool? value) => setState(() => _consent = value ?? false);

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final textTheme = Theme.of(context).textTheme;

    if (result.isIndividualOnly) {
      return _IndividualResult(
        result: result,
        city: widget.city,
        phoneController: _phoneController,
        consent: _consent,
        onConsentChanged: _setConsent,
        isSubmitting: widget.consultationSubmitting,
        isRequested: widget.consultationRequested,
        canGoBack: widget.canGoBack,
        onBack: widget.onBack,
        onConsult: () {
          widget.onSubmitPhone(_phoneController.text);
          widget.onRequestConsultation();
        },
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.canGoBack) ...[
            _BackLink(onBack: widget.onBack),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (result.isRoughEstimate)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Text(
                'Даних поки недостатньо для точного сценарію — нижче '
                'орієнтовні рівні. Точний план визначає лікар після огляду '
                'і КТ.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.tealDark,
                ),
              ),
            ),
          Text(
            result.clinicalSummary,
            style: textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          _CitySwitch(city: widget.city, onChanged: widget.onCityChanged),
          const SizedBox(height: AppSpacing.lg),

          if (result.kind == ResultKind.fullArch) ...[
            _SizeCards(
              combos: result.combos,
              showPrices: widget.phoneSubmitted,
              onSelect: widget.onArchSizeChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (result.primaryTierLabel.isNotEmpty) ...[
            _TierChips(
              label: result.primaryTierLabel,
              options: const ['Базовий', 'Оптимальний', 'Преміальний'],
              selectedIndex: widget.primaryTierIndex,
              onSelected: widget.onPrimaryTierChanged,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (result.secondaryTierLabel.isNotEmpty)
            _TierChips(
              label: result.secondaryTierLabel,
              options: const ['Базовий', 'Оптимальний', 'Преміальний'],
              selectedIndex: widget.secondaryTierIndex,
              onSelected: widget.onSecondaryTierChanged,
            ),
          if (result.tempCrownAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            _CheckRow(
              value: widget.tempCrownRequested,
              onChanged: (v) => widget.onTempCrownChanged(v ?? false),
              label: 'Потрібна тимчасова коронка на період лікування',
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          if (!widget.phoneSubmitted)
            _PhoneGate(
              controller: _phoneController,
              consent: _consent,
              onConsentChanged: _setConsent,
              onSubmit: () => widget.onSubmitPhone(_phoneController.text),
            )
          else ...[
            _RevealedTotal(result: result),
            if (result.kind != ResultKind.fullArch &&
                result.combos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _ComboCards(
                combos: result.combos,
                onSelect: (combo) {
                  widget.onPrimaryTierChanged(combo.primaryTierIndex);
                  widget.onSecondaryTierChanged(combo.secondaryTierIndex);
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            for (final note in result.noticeTexts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  note,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            _ExtrasBlock(result: result, city: widget.city),
            const SizedBox(height: AppSpacing.xl),
            if (widget.consultationRequested)
              const _ConsultationConfirmed()
            else
              _PrimaryButton(
                label: 'Хочу записатися на консультацію',
                loading: widget.consultationSubmitting,
                onPressed: widget.consultationSubmitting
                    ? null
                    : widget.onRequestConsultation,
              ),
            const SizedBox(height: AppSpacing.sm),
            _ConsultInfo(city: widget.city),
          ],
          const SizedBox(height: AppSpacing.xl),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Назад'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.muted,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _CitySwitch extends StatelessWidget {
  const _CitySwitch({required this.city, required this.onChanged});

  final ServiceCity city;
  final ValueChanged<ServiceCity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final c in ServiceCity.values)
          ChoiceChip(
            label: Text(c.label),
            selected: c == city,
            onSelected: (_) => onChanged(c),
          ),
      ],
    );
  }
}

class _TierChips extends StatelessWidget {
  const _TierChips({
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < options.length; i++)
              ChoiceChip(
                label: Text(options[i]),
                selected: i == selectedIndex,
                onSelected: (_) => onSelected(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.label,
    this.dark = false,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white70 : AppColors.inkSoft;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            side: BorderSide(color: dark ? Colors.white70 : AppColors.muted),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeCards extends StatelessWidget {
  const _SizeCards({
    required this.combos,
    required this.showPrices,
    required this.onSelect,
  });

  final List<TierCombo> combos;
  final bool showPrices;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 640;
        final cards = [
          for (final combo in combos)
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth - AppSpacing.sm * 2) / 3
                  : double.infinity,
              child: _SizeCard(
                combo: combo,
                showPrice: showPrices,
                onTap: () => onSelect(combo.primaryTierIndex),
              ),
            ),
        ];
        return isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards,
              )
            : Column(
                children: [
                  for (final c in cards) ...[
                    c,
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
      },
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.combo,
    required this.showPrice,
    required this.onTap,
  });

  final TierCombo combo;
  final bool showPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecommended = combo.primaryTierIndex == 6;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: combo.isCurrent ? AppColors.tealSoft : AppColors.paper,
          border: Border.all(
            color: combo.isCurrent ? AppColors.teal : AppColors.line,
            width: combo.isCurrent ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              combo.label,
              style: textTheme.titleLarge?.copyWith(color: AppColors.ink),
            ),
            Text(
              '${combo.label.replaceAll('All-on-', '')} імплантів на щелепу',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            if (isRecommended)
              Text(
                'Часто рекомендований варіант',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.tealDark,
                ),
              ),
            if (showPrice) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Перший етап: ${_formatEur(combo.eurTotal)}',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.inkSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.onSubmitted,
    this.dark = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (!dark) {
      return TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        inputFormatters: [_phoneInputFormatter],
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          labelText: 'Номер телефону',
          hintText: '0XX XXX XX XX',
        ),
      );
    }
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [_phoneInputFormatter],
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Номер телефону',
        hintText: '0XX XXX XX XX',
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: AppColors.navySoft,
        border: border(Colors.white24),
        enabledBorder: border(Colors.white24),
        focusedBorder: border(Colors.white),
      ),
    );
  }
}

const _consentText =
    'Погоджуюсь на обробку персональних даних і зв’язок щодо консультації';

class _PhoneGate extends StatelessWidget {
  const _PhoneGate({
    required this.controller,
    required this.consent,
    required this.onConsentChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool consent;
  final ValueChanged<bool?> onConsentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ваш персональний розрахунок готовий',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ми підібрали можливий варіант імплантації та розрахували '
            'стандартні етапи. Введіть номер телефону, щоб відкрити повний '
            'розрахунок і порівняти варіанти. Без SMS-коду — результат '
            'відкриється одразу.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PhoneField(
            controller: controller,
            dark: true,
            onSubmitted: (value) {
              if (consent && isValidPhone(value)) onSubmit();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            value: consent,
            onChanged: onConsentChanged,
            label: _consentText,
            dark: true,
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSubmit = consent && isValidPhone(value.text);
              return _PrimaryButton(
                label: 'Показати розрахунок',
                onPressed: canSubmit ? onSubmit : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _RevealedTotal extends StatelessWidget {
  const _RevealedTotal({required this.result});

  final CalculatorResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft);
    final isArch = result.kind == ResultKind.fullArch;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isArch) ...[
            Text('Перший етап — тимчасові зуби за 3–7 днів', style: label),
            Text(
              '${_formatEur(result.archFirstStageEur)} + '
              '${_formatUah(result.archFirstStageUah)}',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Постійна конструкція — приблизно через 6 місяців',
                style: label),
            Text(
              '+ ${_formatEur(result.archFullEur - result.archFirstStageEur)} '
              '+ ${_formatUah(result.archFullUah - result.archFirstStageUah)}',
              style: textTheme.titleLarge?.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Загальна вартість до постійної конструкції', style: label),
            Text(
              '${_formatEur(result.archFullEur)} + '
              '${_formatUah(result.archFullUah)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ] else
            Text(
              _formatEur(result.eurAmount),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          Text(
            '≈ ${_formatUah(result.uahEquivalentTotal)} за курсом НБУ',
            style: label,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in result.breakdown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatMoney(line.money),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComboCards extends StatelessWidget {
  const _ComboCards({required this.combos, required this.onSelect});

  final List<TierCombo> combos;
  final ValueChanged<TierCombo> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 640;
        final cards = [
          for (final combo in combos)
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth -
                            AppSpacing.sm * (combos.length - 1)) /
                        combos.length
                  : double.infinity,
              child: InkWell(
                onTap: combo.isCurrent ? null : () => onSelect(combo),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: combo.isCurrent
                        ? AppColors.tealSoft
                        : AppColors.paperDim,
                    border: Border.all(
                      color: combo.isCurrent ? AppColors.teal : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        combo.isCurrent ? 'Поточна' : 'Обрати',
                        style: textTheme.labelMedium?.copyWith(
                          color: combo.isCurrent
                              ? AppColors.tealDark
                              : AppColors.muted,
                        ),
                      ),
                      Text(
                        combo.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                      Text(
                        _formatEur(combo.eurTotal),
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ];
        return isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards,
              )
            : Column(
                children: [
                  for (final c in cards) ...[
                    c,
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
      },
    );
  }
}

/// ТЗ §6.1/§4.7 — procedures that may be needed but are never summed into
/// the total.
class _ExtrasBlock extends StatelessWidget {
  const _ExtrasBlock({required this.result, required this.city});

  final CalculatorResult result;
  final ServiceCity city;

  String _priceFor(CatalogEntry entry) {
    if (entry == ServiceCatalog.sedationHour &&
        result.sedationEstimate != null) {
      return 'орієнтовно ${_formatMoney(result.sedationEstimate!)}';
    }
    final price = entry.priceFor(city);
    if (price == null) return 'за показаннями';
    final suffix = entry == ServiceCatalog.augmentSegment ? '/сегмент' : '';
    return '${_formatMoney(price)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Може знадобитися додатково',
            style: textTheme.titleLarge?.copyWith(color: AppColors.ink),
          ),
          Text(
            'Не входить у суму — лише якщо лікар підтвердить після огляду і '
            'КТ.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in ServiceCatalog.notAutoIncluded)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.displayName,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _priceFor(entry),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ТЗ §6.3 — consultation price and hours next to the booking CTA.
class _ConsultInfo extends StatelessWidget {
  const _ConsultInfo({required this.city});

  final ServiceCity city;

  @override
  Widget build(BuildContext context) {
    final price = ServiceCatalog.consultImplant.priceFor(city);
    return Text(
      'Консультація імплантолога в місті ${city.label}'
      '${price == null ? '' : ' — ${_formatMoney(price)}'}. '
      'Графік: ${city.schedule}.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paperDim,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        CalculatorResult.warningText,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _IndividualResult extends StatelessWidget {
  const _IndividualResult({
    required this.result,
    required this.city,
    required this.phoneController,
    required this.consent,
    required this.onConsentChanged,
    required this.isSubmitting,
    required this.isRequested,
    required this.canGoBack,
    required this.onBack,
    required this.onConsult,
  });

  final CalculatorResult result;
  final ServiceCity city;
  final TextEditingController phoneController;
  final bool consent;
  final ValueChanged<bool?> onConsentChanged;
  final bool isSubmitting;
  final bool isRequested;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canGoBack) ...[
            _BackLink(onBack: onBack),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            result.individualMessage ?? '',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isRequested)
            const _ConsultationConfirmed()
          else ...[
            _PhoneField(
              controller: phoneController,
              onSubmitted: (value) {
                if (consent && !isSubmitting && isValidPhone(value)) {
                  onConsult();
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _CheckRow(
              value: consent,
              onChanged: onConsentChanged,
              label: _consentText,
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: phoneController,
              builder: (context, value, _) {
                final canSubmit =
                    consent && !isSubmitting && isValidPhone(value.text);
                return _PrimaryButton(
                  label: result.individualCta ?? 'Записатися на консультацію',
                  loading: isSubmitting,
                  onPressed: canSubmit ? onConsult : null,
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _ConsultInfo(city: city),
          const SizedBox(height: AppSpacing.lg),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _ConsultationConfirmed extends StatelessWidget {
  const _ConsultationConfirmed();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.teal),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Дякуємо! У робочий час адміністратор зателефонує протягом 15 '
            'хвилин, поза робочим часом — зранку наступного робочого дня.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }
}
