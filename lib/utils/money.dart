import 'package:intl/intl.dart';

final NumberFormat _soles = NumberFormat.currency(
  locale: 'es_PE',
  symbol: 'S/ ',
  decimalDigits: 2,
);

/// Formatea un monto como soles peruanos, ej. `S/ 15.00`.
String money(double value) => _soles.format(value);
