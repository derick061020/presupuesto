import 'dart:math' as math;

import 'package:flutter/foundation.dart' hide Category;

import '../models/app_data.dart';
import '../services/storage.dart';

/// Estado central de la app: datos + lógica del ciclo de 28 días, días plus,
/// ahorro automático y persistencia. Las 3 pestañas leen/escriben de aquí.
class BudgetState extends ChangeNotifier {
  // ---- Constantes de negocio ----
  static const double dailyBase = 15; // límite base de comida por día
  static const double dailyMax = 30; // tope visual en día plus
  static const int plusPerWeek = 3; // días plus permitidos por semana
  static const int cycleDays = 28; // duración del "mes" (4 semanas)

  /// Valor que aporta al ahorro cada día plus no usado.
  static const double plusValue = dailyMax - dailyBase;

  // ---- Estado persistido ----
  DateTime _anchorDate = DateTime.now();
  int _lastProcessedDay = -1; // último día (absoluto) ya contabilizado
  double fixedSavings = 0;
  double accumulatedSavings = 0;
  final List<Category> categories = [];
  final List<Expense> expenses = [];
  final List<FixedPayment> fixedPayments = [];
  final List<Income> incomes = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  DateTime get anchorDate => _anchorDate;

  // -------------------------------------------------------------------------
  // Carga / guardado
  // -------------------------------------------------------------------------

  Future<void> load() async {
    final data = await Storage.load();
    if (data == null) {
      _seedDefaults();
      _anchorDate = DateTime.now();
      _lastProcessedDay = -1;
      _loaded = true;
      await _persist();
      notifyListeners();
      return;
    }
    _fromJson(data);
    _loaded = true;
    _processRollover(); // cierra días/semanas/meses transcurridos
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => Storage.save(_toJson());

  void _seedDefaults() {
    categories
      ..clear()
      ..addAll([
        Category(
          id: kFoodCategoryId,
          name: 'Comida',
          monthlyBudget: dailyBase * cycleDays, // 420
          isFood: true,
        ),
        Category(id: _genId(), name: 'Salidas', monthlyBudget: 200),
        Category(id: _genId(), name: 'Ocio', monthlyBudget: 150),
      ]);
  }

  Map<String, dynamic> _toJson() => {
        'anchorDate': _anchorDate.toIso8601String(),
        'lastProcessedDay': _lastProcessedDay,
        'fixedSavings': fixedSavings,
        'accumulatedSavings': accumulatedSavings,
        'categories': categories.map((c) => c.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'fixedPayments': fixedPayments.map((p) => p.toJson()).toList(),
        'incomes': incomes.map((i) => i.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> json) {
    _anchorDate =
        DateTime.tryParse(json['anchorDate'] as String? ?? '') ?? DateTime.now();
    _lastProcessedDay = json['lastProcessedDay'] as int? ?? -1;
    fixedSavings = (json['fixedSavings'] as num?)?.toDouble() ?? 0;
    accumulatedSavings = (json['accumulatedSavings'] as num?)?.toDouble() ?? 0;
    categories
      ..clear()
      ..addAll(((json['categories'] as List?) ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>)));
    expenses
      ..clear()
      ..addAll(((json['expenses'] as List?) ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>)));
    fixedPayments
      ..clear()
      ..addAll(((json['fixedPayments'] as List?) ?? [])
          .map((e) => FixedPayment.fromJson(e as Map<String, dynamic>)));
    incomes
      ..clear()
      ..addAll(((json['incomes'] as List?) ?? [])
          .map((e) => Income.fromJson(e as Map<String, dynamic>)));
    if (categories.isEmpty) _seedDefaults();
  }

  // -------------------------------------------------------------------------
  // Cálculo del ciclo
  // -------------------------------------------------------------------------

  /// Normaliza a medianoche local (descarta la hora).
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Días de calendario entre dos fechas, contando el cambio de día a las 00:00
  /// hora local del teléfono. Robusto frente a cambios de horario (DST).
  static int _daysBetween(DateTime from, DateTime to) =>
      (_dateOnly(to).difference(_dateOnly(from)).inHours / 24).round();

  /// Días absolutos transcurridos desde el ancla (puede crecer más allá de 28).
  /// El día cambia a las 00:00 de la zona horaria local, no a las 24h exactas.
  int get _absoluteDay => _daysBetween(_anchorDate, DateTime.now());

  /// Día dentro del ciclo actual (0..27).
  int get currentCycleDay => _absoluteDay % cycleDays;

  /// Día mostrado al usuario (1..28).
  int get displayDay => currentCycleDay + 1;

  /// Semana actual dentro del ciclo (0..3).
  int get currentWeek => currentCycleDay ~/ 7;

  /// Semana mostrada (1..4).
  int get displayWeek => currentWeek + 1;

  /// Mes (ciclo) actual mostrado (1..n).
  int get displayMonth => (_absoluteDay ~/ cycleDays) + 1;

  /// Si se puede retroceder un día (no estamos en el día 1 del primer ciclo).
  bool get canGoBackDay => _absoluteDay > 0;

  /// Gasto de comida en un día del ciclo dado (0..27).
  double foodSpentOnCycleDay(int cycleDay) {
    var total = 0.0;
    for (final e in expenses) {
      if (e.categoryId == kFoodCategoryId && e.dayIndex == cycleDay) {
        total += e.amount;
      }
    }
    return total;
  }

  /// Gasto de comida de hoy.
  double get foodSpentToday => foodSpentOnCycleDay(currentCycleDay);

  /// Restante respecto al límite base de hoy (no baja de 0).
  double get remainingBaseToday => math.max(0, dailyBase - foodSpentToday);

  /// Días plus usados en la semana actual (días con gasto > base).
  int get plusUsedThisWeek {
    final start = currentWeek * 7;
    var used = 0;
    for (var d = start; d < start + 7; d++) {
      if (foodSpentOnCycleDay(d) > dailyBase) used++;
    }
    return used;
  }

  /// Días plus restantes esta semana (puede ser negativo = sobregiro).
  int get plusRemainingThisWeek => plusPerWeek - plusUsedThisWeek;

  // -------------------------------------------------------------------------
  // Rollover: cierre de días, semanas y meses transcurridos -> ahorro
  // -------------------------------------------------------------------------

  void _processRollover() {
    final today = _absoluteDay;
    if (today - 1 <= _lastProcessedDay) return; // nada nuevo que cerrar

    for (var d = _lastProcessedDay + 1; d < today; d++) {
      final cycleDay = d % cycleDays;

      // Ahorro diario sobre la base 15.
      final spent = foodSpentOnCycleDay(cycleDay);
      accumulatedSavings += math.max(0, dailyBase - spent);

      // Cierre de semana: aportar plus no usados (15 c/u).
      if ((d + 1) % 7 == 0) {
        final weekStart = (cycleDay ~/ 7) * 7;
        var used = 0;
        for (var wd = weekStart; wd < weekStart + 7; wd++) {
          if (foodSpentOnCycleDay(wd) > dailyBase) used++;
        }
        accumulatedSavings += math.max(0, plusPerWeek - used) * plusValue;
      }

      // Cierre de mes (28 días): reiniciar gastos y desmarcar pagos.
      if ((d + 1) % cycleDays == 0) {
        expenses.clear();
        for (final p in fixedPayments) {
          p.paid = false;
        }
      }
    }
    _lastProcessedDay = today - 1;
  }

  // -------------------------------------------------------------------------
  // Resumen mensual
  // -------------------------------------------------------------------------

  double get totalIncome => incomes.fold(0.0, (s, i) => s + i.amount);
  double get totalBudgets =>
      categories.fold(0.0, (s, c) => s + c.monthlyBudget);
  double get totalFixedPayments =>
      fixedPayments.fold(0.0, (s, p) => s + p.amount);

  /// Pagos fijos ya realizados (marcados como hechos).
  double get paidFixedPayments =>
      fixedPayments.where((p) => p.paid).fold(0.0, (s, p) => s + p.amount);

  /// Gasto real acumulado del mes (suma de todos los gastos registrados).
  double get totalSpent => expenses.fold(0.0, (s, e) => s + e.amount);

  /// Disponible tras los gastos reales, pagos fijos ya hechos y ahorro fijo.
  double get availableMonthly =>
      totalIncome - totalSpent - paidFixedPayments - fixedSavings;

  /// Gasto del mes para una categoría.
  double spentForCategory(String categoryId) {
    var total = 0.0;
    for (final e in expenses) {
      if (e.categoryId == categoryId) total += e.amount;
    }
    return total;
  }

  double get totalSavings => fixedSavings + accumulatedSavings;

  // -------------------------------------------------------------------------
  // Mutaciones (todas persisten y notifican)
  // -------------------------------------------------------------------------

  void addExpense({
    required String categoryId,
    required double amount,
    String note = '',
  }) {
    expenses.add(Expense(
      id: _genId(),
      categoryId: categoryId,
      amount: amount,
      dayIndex: currentCycleDay,
      note: note,
    ));
    _commit();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    _commit();
  }

  void addCategory(String name, double budget) {
    categories.add(Category(id: _genId(), name: name, monthlyBudget: budget));
    _commit();
  }

  void updateCategory(String id, {String? name, double? budget}) {
    final c = categories.firstWhere((c) => c.id == id);
    if (name != null) c.name = name;
    if (budget != null) c.monthlyBudget = budget;
    _commit();
  }

  void deleteCategory(String id) {
    if (id == kFoodCategoryId) return; // no se borra la categoría de comida
    categories.removeWhere((c) => c.id == id);
    expenses.removeWhere((e) => e.categoryId == id);
    _commit();
  }

  void addFixedPayment(String name, double amount) {
    fixedPayments
        .add(FixedPayment(id: _genId(), name: name, amount: amount));
    _commit();
  }

  void togglePaymentPaid(String id, bool paid) {
    fixedPayments.firstWhere((p) => p.id == id).paid = paid;
    _commit();
  }

  void deletePayment(String id) {
    fixedPayments.removeWhere((p) => p.id == id);
    _commit();
  }

  void addIncome(String name, double amount) {
    incomes.add(Income(id: _genId(), name: name, amount: amount));
    _commit();
  }

  void deleteIncome(String id) {
    incomes.removeWhere((i) => i.id == id);
    _commit();
  }

  void setFixedSavings(double value) {
    fixedSavings = value;
    _commit();
  }

  /// Edita directamente el monto del ahorro acumulado.
  void setAccumulatedSavings(double value) {
    accumulatedSavings = math.max(0, value);
    _commit();
  }

  /// Retira [amount] del ahorro. Descuenta primero del acumulado y, si no
  /// alcanza, del fijo. Devuelve lo realmente retirado (limitado al total).
  double withdrawSavings(double amount) {
    final taken = math.min(math.max(0.0, amount), totalSavings);
    final fromAccumulated = math.min(taken, accumulatedSavings);
    accumulatedSavings -= fromAccumulated;
    fixedSavings -= taken - fromAccumulated;
    _commit();
    return taken;
  }

  /// Solo para pruebas: adelanta el ciclo un día (mueve el ancla atrás).
  void debugAdvanceDay() {
    _anchorDate = _anchorDate.subtract(const Duration(days: 1));
    _processRollover();
    _commit();
  }

  /// Solo para pruebas: retrocede el ciclo un día (mueve el ancla adelante).
  /// No baja del día 1 del primer ciclo.
  void debugGoBackDay() {
    if (_absoluteDay <= 0) return;
    _anchorDate = _anchorDate.add(const Duration(days: 1));
    if (_lastProcessedDay >= _absoluteDay) {
      _lastProcessedDay = _absoluteDay - 1;
    }
    _commit();
  }

  void _commit() {
    _persist();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Utilidades
  // -------------------------------------------------------------------------

  static int _idCounter = 0;
  String _genId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
}
