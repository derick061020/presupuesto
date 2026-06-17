import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/budget_state.dart';
import '../theme.dart';
import '../utils/money.dart';
import '../widgets/name_amount_dialog.dart';
import '../widgets/ui.dart';

/// Pestaña "Ahorro": monto fijo + ahorro acumulado automático.
class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    final scheme = Theme.of(context).colorScheme;
    final fixedRatio = state.totalSavings <= 0
        ? 0.0
        : state.fixedSavings / state.totalSavings;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text('Ahorro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 12),

            // ---- Hero total ----
            GradientCard(
              colors: AppTheme.savings,
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const GlassPill(
                      label: 'Total ahorrado', icon: Icons.savings),
                  const SizedBox(height: 16),
                  AnimatedMoney(
                    state.totalSavings,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Barra de composición fijo vs acumulado.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(
                              height: 8,
                              color: Colors.white.withValues(alpha: 0.3)),
                          Container(
                            height: 8,
                            width: c.maxWidth * fixedRatio,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fijo ${money(state.fixedSavings)}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12)),
                      Text('Acumulado ${money(state.accumulatedSavings)}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: state.totalSavings <= 0
                          ? null
                          : () => _withdraw(context, state),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Retirar ahorro',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Monto fijo ----
            SoftCard(
              onTap: () async {
                final r = await showNameAmountDialog(
                  context,
                  title: 'Monto fijo de ahorro',
                  nameLabel: 'Etiqueta',
                  amountLabel: 'Monto',
                  initialName: 'Ahorro fijo',
                  initialAmount: state.fixedSavings,
                );
                if (r != null) state.setFixedSavings(r.amount);
              },
              child: Row(
                children: [
                  CircleIcon(Icons.lock, color: scheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monto fijo',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Lo defines tú · toca para editar',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  AnimatedMoney(state.fixedSavings,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Acumulado ----
            SoftCard(
              child: Row(
                children: [
                  CircleIcon(Icons.auto_graph, color: const Color(0xFF2193B0)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ahorro acumulado',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Crece solo con lo que no gastas',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  AnimatedMoney(state.accumulatedSavings,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Explicación ----
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: scheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cada día que cierra suma a tu ahorro lo que no gastaste '
                      'de los S/ ${BudgetState.dailyBase.toStringAsFixed(0)}. '
                      'Y al terminar la semana, los días plus que no usaste '
                      'también van al ahorro '
                      '(S/ ${BudgetState.plusValue.toStringAsFixed(0)} cada uno).',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, BudgetState state) async {
    final r = await showNameAmountDialog(
      context,
      title: 'Retirar ahorro',
      nameLabel: 'Motivo',
      amountLabel: 'Monto a retirar',
      initialName: 'Retiro',
      initialAmount: state.totalSavings,
    );
    if (r == null) return;
    final taken = state.withdrawSavings(r.amount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Retiraste ${money(taken)} del ahorro')),
    );
  }
}
