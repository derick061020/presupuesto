import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_data.dart';
import '../state/budget_state.dart';
import '../theme.dart';
import '../utils/money.dart';
import '../widgets/expense_dialog.dart';
import '../widgets/name_amount_dialog.dart';
import '../widgets/ui.dart';

/// Pestaña "Mensual": ingresos, presupuestos por categoría y pagos fijos.
class MonthlyScreen extends StatelessWidget {
  const MonthlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExpenseDialog(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Gasto'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text('Vista mensual',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            _SummaryHero(state: state),
            const SizedBox(height: 20),

            const SectionTitle('Gastos del mes'),
            if (state.expenses.isEmpty)
              _emptyHint(context, 'Aún no registras gastos este mes.'),
            for (final e in state.expenses.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExpenseTile(state: state, expenseId: e.id),
              ),

            const SizedBox(height: 8),
            SectionTitle('Categorías', onAdd: () async {
              final r = await showNameAmountDialog(
                context,
                title: 'Nueva categoría',
                nameLabel: 'Nombre',
                amountLabel: 'Presupuesto mensual',
              );
              if (r != null) state.addCategory(r.name, r.amount);
            }),
            for (final c in state.categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryTile(state: state, categoryId: c.id),
              ),

            const SizedBox(height: 8),
            SectionTitle('Pagos fijos', onAdd: () async {
              final r = await showNameAmountDialog(
                context,
                title: 'Nuevo pago fijo',
                nameLabel: 'Nombre',
                amountLabel: 'Monto mensual',
              );
              if (r != null) state.addFixedPayment(r.name, r.amount);
            }),
            if (state.fixedPayments.isEmpty)
              _emptyHint(context, 'Sin pagos fijos.'),
            for (final p in state.fixedPayments)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: p.paid,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        onChanged: (v) =>
                            state.togglePaymentPaid(p.id, v ?? false),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: p.paid
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: p.paid
                                      ? scheme.onSurfaceVariant
                                      : null,
                                )),
                            Text(money(p.amount),
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 20, color: scheme.onSurfaceVariant),
                        onPressed: () => state.deletePayment(p.id),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),
            SectionTitle('Ingresos', onAdd: () async {
              final r = await showNameAmountDialog(
                context,
                title: 'Nuevo ingreso',
                nameLabel: 'Nombre',
                amountLabel: 'Monto',
              );
              if (r != null) state.addIncome(r.name, r.amount);
            }),
            if (state.incomes.isEmpty) _emptyHint(context, 'Sin ingresos.'),
            for (final i in state.incomes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      CircleIcon(Icons.payments, color: Colors.green.shade600),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(money(i.amount),
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 20, color: scheme.onSurfaceVariant),
                        onPressed: () => state.deleteIncome(i.id),
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

  Widget _emptyHint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.state});
  final BudgetState state;

  @override
  Widget build(BuildContext context) {
    final available = state.availableMonthly;
    final negative = available < 0;
    return GradientCard(
      colors: negative ? AppTheme.danger : AppTheme.monthly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassPill(label: 'Disponible este mes', icon: Icons.savings),
          const SizedBox(height: 14),
          AnimatedMoney(
            available,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('Ingresos', state.totalIncome),
              _miniStat('Gastos', state.totalSpent),
              _miniStat('Pagos', state.paidFixedPayments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(money(value),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12)),
          ],
        ),
      );
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.state, required this.expenseId});
  final BudgetState state;
  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = state.expenses.firstWhere((x) => x.id == expenseId);
    final category = state.categories.firstWhere(
      (c) => c.id == e.categoryId,
      orElse: () => Category(id: '', name: 'Sin categoría', monthlyBudget: 0),
    );

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleIcon(category.isFood ? Icons.restaurant : Icons.sell,
              color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(money(e.amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  e.note.isEmpty ? category.name : '${category.name} · ${e.note}',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: scheme.onSurfaceVariant),
            onPressed: () => state.deleteExpense(e.id),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.state, required this.categoryId});
  final BudgetState state;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final c = state.categories.firstWhere((c) => c.id == categoryId);
    final spent = state.spentForCategory(c.id);
    final ratio =
        c.monthlyBudget <= 0 ? 0.0 : (spent / c.monthlyBudget).clamp(0.0, 1.0);
    final over = spent > c.monthlyBudget;
    final scheme = Theme.of(context).colorScheme;
    final barColors = over ? AppTheme.danger : AppTheme.daily;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIcon(c.isFood ? Icons.restaurant : Icons.sell,
                  color: over ? scheme.error : scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.edit_outlined,
                    size: 20, color: scheme.onSurfaceVariant),
                onPressed: () async {
                  final r = await showNameAmountDialog(
                    context,
                    title: 'Editar categoría',
                    nameLabel: 'Nombre',
                    amountLabel: 'Presupuesto mensual',
                    initialName: c.name,
                    initialAmount: c.monthlyBudget,
                  );
                  if (r != null) {
                    state.updateCategory(c.id, name: r.name, budget: r.amount);
                  }
                },
              ),
              if (!c.isFood)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: scheme.onSurfaceVariant),
                  onPressed: () => state.deleteCategory(c.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de progreso con degradado.
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: ratio),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Container(
                    height: 10,
                    width: constraints.maxWidth * v,
                    decoration: BoxDecoration(
                      gradient: appGradient(barColors),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${money(spent)} de ${money(c.monthlyBudget)}'
            '${over ? '  ·  excedido' : ''}',
            style: TextStyle(
              color: over ? scheme.error : scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: over ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
