import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_data.dart';
import '../state/budget_state.dart';
import '../theme.dart';
import '../utils/money.dart';
import '../widgets/expense_dialog.dart';
import '../widgets/semicircle_gauge.dart';
import '../widgets/ui.dart';

/// Pestaña "Diario": gauge del presupuesto de comida de hoy + días plus.
class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    final scheme = Theme.of(context).colorScheme;

    final spent = state.foodSpentToday;
    final remaining = state.remainingBaseToday;
    final overBase = spent > BudgetState.dailyBase;
    final plusLeft = state.plusRemainingThisWeek;

    final todayExpenses = state.expenses
        .where((e) =>
            e.categoryId == kFoodCategoryId &&
            e.dayIndex == state.currentCycleDay)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showExpenseDialog(context, state, lockCategoryId: kFoodCategoryId),
        icon: const Icon(Icons.add),
        label: const Text('Registrar gasto'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            // ---- Header ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoy',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                    Text(
                      'Día ${state.displayDay} · Semana ${state.displayWeek} · Mes ${state.displayMonth}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Retroceder un día',
                      icon: const Icon(Icons.fast_rewind),
                      onPressed: state.canGoBackDay
                          ? () => state.debugGoBackDay()
                          : null,
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Avanzar un día',
                      icon: const Icon(Icons.fast_forward),
                      onPressed: () => state.debugAdvanceDay(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Hero con gauge ----
            GradientCard(
              colors: overBase ? AppTheme.warn : AppTheme.daily,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassPill(
                      label: overBase
                          ? 'Día plus activo'
                          : 'Presupuesto del día',
                      icon: overBase ? Icons.bolt : Icons.restaurant,
                    ),
                  ),
                  SemicircleGauge(
                    value: spent,
                    base: BudgetState.dailyBase,
                    max: BudgetState.dailyMax,
                    gradient: const [Colors.white, Color(0xFFEAFFF6)],
                    overflowGradient: const [Colors.white, Color(0xFFFFE3E3)],
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedMoney(
                          remaining,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          overBase ? 'sobre los S/ 15' : 'te quedan hoy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeroStat(
                          label: 'Gastado', value: money(spent)),
                      Container(
                          width: 1, height: 30,
                          color: Colors.white.withValues(alpha: 0.3)),
                      _HeroStat(
                        label: 'Límite',
                        value: overBase ? 'S/ 30' : 'S/ 15',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Días plus ----
            _PlusDaysCard(plusLeft: plusLeft, used: state.plusUsedThisWeek),
            const SizedBox(height: 20),

            // ---- Gastos de hoy ----
            const SectionTitle('Gastos de hoy'),
            if (todayExpenses.isEmpty)
              SoftCard(
                child: Row(
                  children: [
                    CircleIcon(Icons.lunch_dining, color: scheme.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Aún no registras gastos hoy.\n¡Vas bien!',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final e in todayExpenses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        CircleIcon(Icons.restaurant, color: scheme.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(money(e.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              if (e.note.isNotEmpty)
                                Text(e.note,
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 20, color: scheme.onSurfaceVariant),
                          onPressed: () => state.deleteExpense(e.id),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
      ],
    );
  }
}

class _PlusDaysCard extends StatelessWidget {
  const _PlusDaysCard({required this.plusLeft, required this.used});
  final int plusLeft;
  final int used;

  @override
  Widget build(BuildContext context) {
    final over = plusLeft < 0;
    return GradientCard(
      colors: over ? AppTheme.danger : AppTheme.monthly,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(over ? Icons.warning_amber_rounded : Icons.bolt,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  over
                      ? 'Te pasaste ${-plusLeft} día(s) plus'
                      : 'Días plus esta semana',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  over
                      ? 'Usaste $used de ${BudgetState.plusPerWeek}'
                      : 'Te quedan $plusLeft de ${BudgetState.plusPerWeek}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < BudgetState.plusPerWeek; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < used ? Icons.bolt : Icons.bolt_outlined,
                    color: i < used
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    size: 26,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
