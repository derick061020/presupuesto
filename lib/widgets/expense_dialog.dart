import 'package:flutter/material.dart';

import '../state/budget_state.dart';

/// Diálogo para registrar un gasto. Si [lockCategoryId] viene dado, la categoría
/// queda fija (ej. el gasto diario de Comida).
Future<void> showExpenseDialog(
  BuildContext context,
  BudgetState state, {
  String? lockCategoryId,
}) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var categoryId = lockCategoryId ?? state.categories.first.id;
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Registrar gasto'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lockCategoryId == null)
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    for (final c in state.categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => categoryId = v!),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.categories
                        .firstWhere((c) => c.id == lockCategoryId)
                        .name,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
              TextFormField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: 'S/ ',
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final amount =
                  double.parse(amountCtrl.text.replaceAll(',', '.'));
              state.addExpense(
                categoryId: categoryId,
                amount: amount,
                note: noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}
