import 'package:flutter/material.dart';
import 'package:yeremchuk_dental_calculator/calculator/data/service_catalog.dart';
import 'package:yeremchuk_dental_calculator/calculator/models/calculator_result.dart';
import 'package:yeremchuk_dental_calculator/theme/app_colors.dart';
import 'package:yeremchuk_dental_calculator/theme/app_spacing.dart';

String _formatEur(double v) => '${v.toStringAsFixed(0)} €';
String _formatUah(double v) => '${v.toStringAsFixed(0)} грн';

/// ТЗ §6 — the teaser/result screen. Renders the same widget before and
/// after the phone gate: tier toggles work either way (ТЗ §4.2 "До
/// контакту пацієнт окремо вибирає рівень імпланта й коронки"), only the
/// number itself is blurred until [phoneSubmitted].
class CalculatorResultView extends StatefulWidget {
  const CalculatorResultView({
    required this.result,
    required this.city,
    required this.archSize,
    required this.phoneSubmitted,
    required this.consultationSubmitting,
    required this.consultationRequested,
    required this.onPrimaryTierChanged,
    required this.onSecondaryTierChanged,
    required this.onArchSizeChanged,
    required this.onSubmitPhone,
    required this.onRequestConsultation,
    super.key,
  });

  final CalculatorResult result;
  final ServiceCity city;
  final int archSize;
  final bool phoneSubmitted;
  final bool consultationSubmitting;
  final bool consultationRequested;
  final ValueChanged<int> onPrimaryTierChanged;
  final ValueChanged<int> onSecondaryTierChanged;
  final ValueChanged<int> onArchSizeChanged;
  final ValueChanged<String> onSubmitPhone;
  final VoidCallback onRequestConsultation;

  @override
  State<CalculatorResultView> createState() => _CalculatorResultViewState();
}

class _CalculatorResultViewState extends State<CalculatorResultView> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    if (result.isIndividualOnly) {
      return _IndividualResult(
        result: result,
        onConsult: widget.onRequestConsultation,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.tealDark),
              ),
            ),
          Text(
            result.clinicalSummary,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.city.label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (result.kind == ResultKind.fullArch) ...[
            _SizeCards(
              combos: result.combos,
              onSelect: widget.onArchSizeChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          _TierChips(
            label: result.primaryTierLabel,
            options: const ['Раціональний', 'Оптимальний', 'Преміальний'],
            onSelected: widget.onPrimaryTierChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if (result.secondaryTierLabel.isNotEmpty)
            _TierChips(
              label: result.secondaryTierLabel,
              options: const ['Базовий', 'Оптимальний', 'Преміальний'],
              onSelected: widget.onSecondaryTierChanged,
            ),

          const SizedBox(height: AppSpacing.xl),

          if (!widget.phoneSubmitted)
            _PhoneGate(
              controller: _phoneController,
              onSubmit: () => widget.onSubmitPhone(_phoneController.text),
            )
          else
            _RevealedTotal(result: result, archSize: widget.archSize),

          if (widget.phoneSubmitted) ...[
            const SizedBox(height: AppSpacing.lg),
            if (result.kind != ResultKind.fullArch && result.combos.isNotEmpty)
              _ComboCards(combos: result.combos),
            const SizedBox(height: AppSpacing.lg),
            if (result.noticeTexts.isNotEmpty) ...[
              for (final note in result.noticeTexts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    note,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
            ],
            Text(
              'Не входить автоматично',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in ServiceCatalog.notAutoIncluded)
                  Chip(
                    label: Text(entry.displayName),
                    backgroundColor: AppColors.paperDim,
                    side: const BorderSide(color: AppColors.line),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
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
            ),
            const SizedBox(height: AppSpacing.xl),
            if (widget.consultationRequested)
              const _ConsultationConfirmed()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.consultationSubmitting
                      ? null
                      : widget.onRequestConsultation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: widget.consultationSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Хочу записатися на консультацію'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TierChips extends StatelessWidget {
  const _TierChips({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
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
          children: [
            for (var i = 0; i < options.length; i++)
              ChoiceChip(
                label: Text(options[i]),
                selected: false,
                onSelected: (_) => onSelected(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _SizeCards extends StatelessWidget {
  const _SizeCards({required this.combos, required this.onSelect});

  final List<TierCombo> combos;
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
              child: _SizeCard(combo: combo, onTap: () => onSelect(combo.primaryTierIndex)),
            ),
        ];
        return isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
  const _SizeCard({required this.combo, required this.onTap});

  final TierCombo combo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecommended = combo.primaryTierIndex == 6;
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
              ),
            ),
            if (isRecommended)
              Text(
                'Часто рекомендований варіант',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.tealDark,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatEur(combo.eurTotal),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneGate extends StatelessWidget {
  const _PhoneGate({required this.controller, required this.onSubmit});

  final TextEditingController controller;
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
            'Введіть номер телефону, щоб відкрити повний розрахунок і '
            'порівняти варіанти. Без SMS-коду — результат відкриється '
            'одразу.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Номер телефону',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppColors.navySoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.trim().length >= 7) onSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: const Text('Показати розрахунок'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealedTotal extends StatelessWidget {
  const _RevealedTotal({required this.result, required this.archSize});

  final CalculatorResult result;
  final int archSize;

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Перший етап (тимчасова конструкція)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
            Text(
              '${_formatEur(result.archFirstStageEur)} + '
              '${_formatUah(result.archFirstStageUah)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Постійна конструкція (≈6 місяців)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Загальна вартість до постійної конструкції',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
            Text(
              '${_formatEur(result.archFullEur)} + '
              '${_formatUah(result.archFullUah)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ] else ...[
            Text(
              _formatEur(result.eurAmount),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            Text(
              '≈ ${_formatUah(result.uahEquivalentTotal)} за курсом НБУ',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final line in result.breakdown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        line.label,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    Text(
                      line.money.currency == Currency.eur
                          ? _formatEur(line.money.amount)
                          : _formatUah(line.money.amount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ComboCards extends StatelessWidget {
  const _ComboCards({required this.combos});

  final List<TierCombo> combos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 640;
        final cards = [
          for (final combo in combos)
            SizedBox(
              width: isDesktop
                  ? (constraints.maxWidth - AppSpacing.sm * (combos.length - 1)) /
                        combos.length
                  : double.infinity,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: combo.isCurrent ? AppColors.tealSoft : AppColors.paperDim,
                  border: Border.all(
                    color: combo.isCurrent ? AppColors.teal : AppColors.line,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (combo.isCurrent)
                      Text(
                        'Поточна',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.tealDark,
                        ),
                      ),
                    Text(
                      combo.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      _formatEur(combo.eurTotal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ];
        return isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

class _IndividualResult extends StatelessWidget {
  const _IndividualResult({required this.result, required this.onConsult});

  final CalculatorResult result;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.individualMessage ?? '',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConsult,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(result.individualCta ?? 'Записатися'),
            ),
          ),
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
      children: [
        const Icon(Icons.check_circle, color: AppColors.teal),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Дякуємо! У робочий час адміністратор зателефонує протягом 15 '
            'хвилин.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }
}
