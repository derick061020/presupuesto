import 'package:flutter/material.dart';

/// Resultado del diálogo de nombre + monto.
class NameAmount {
  const NameAmount(this.name, this.amount);
  final String name;
  final double amount;
}

/// Diálogo genérico para capturar un nombre y un monto. Sirve para categorías,
/// pagos fijos e ingresos. Devuelve null si se cancela.
Future<NameAmount?> showNameAmountDialog(
  BuildContext context, {
  required String title,
  required String nameLabel,
  required String amountLabel,
  String initialName = '',
  double? initialAmount,
}) {
  final nameCtrl = TextEditingController(text: initialName);
  final amountCtrl = TextEditingController(
    text: initialAmount != null ? initialAmount.toStringAsFixed(2) : '',
  );
  final formKey = GlobalKey<FormState>();

  return showDialog<NameAmount>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: nameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            TextFormField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: amountLabel,
                prefixText: 'S/ ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n < 0) return 'Monto inválido';
                return null;
              },
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
            Navigator.pop(
              ctx,
              NameAmount(
                nameCtrl.text.trim(),
                double.parse(amountCtrl.text.replaceAll(',', '.')),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
