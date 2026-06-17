// Modelos de datos de la app. Todo se serializa a JSON para guardarse local
// mediante shared_preferences.

/// Id de la categoría especial de Comida (presupuesto diario).
const String kFoodCategoryId = 'comida';

/// Categoría de gasto mensual (Comida, Salidas, Ocio, etc.).
class Category {
  Category({
    required this.id,
    required this.name,
    required this.monthlyBudget,
    this.isFood = false,
  });

  final String id;
  String name;
  double monthlyBudget;
  final bool isFood;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlyBudget': monthlyBudget,
        'isFood': isFood,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        monthlyBudget: (json['monthlyBudget'] as num).toDouble(),
        isFood: json['isFood'] as bool? ?? false,
      );
}

/// Un gasto puntual. `dayIndex` es el día del ciclo (0..27) en que se registró.
class Expense {
  Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.dayIndex,
    this.note = '',
  });

  final String id;
  String categoryId;
  double amount;
  int dayIndex;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'dayIndex': dayIndex,
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        amount: (json['amount'] as num).toDouble(),
        dayIndex: json['dayIndex'] as int,
        note: json['note'] as String? ?? '',
      );
}

/// Pago fijo mensual (ej. alquiler, suscripciones).
class FixedPayment {
  FixedPayment({
    required this.id,
    required this.name,
    required this.amount,
    this.paid = false,
  });

  final String id;
  String name;
  double amount;
  bool paid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'paid': paid,
      };

  factory FixedPayment.fromJson(Map<String, dynamic> json) => FixedPayment(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        paid: json['paid'] as bool? ?? false,
      );
}

/// Ingreso mensual (ej. sueldo).
class Income {
  Income({
    required this.id,
    required this.name,
    required this.amount,
  });

  final String id;
  String name;
  double amount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}
