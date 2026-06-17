import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local simple: guarda/lee un único blob JSON con todo el estado.
class Storage {
  static const _key = 'budget_state_v1';

  /// Devuelve el estado guardado como mapa, o null si no hay nada.
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Guarda el estado completo.
  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }
}
