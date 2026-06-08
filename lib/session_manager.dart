import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();

  static const _keyToken        = 'session_token';
  static const _keyLoginTime    = 'session_login_time';
  static const _keyLastActivity = 'session_last_activity';

  // Guardar sesión al hacer login
  static Future<void> saveSession(String token) async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _keyToken,        value: token);
    await _storage.write(key: _keyLoginTime,    value: now);
    await _storage.write(key: _keyLastActivity, value: now);
  }

  // Actualizar última actividad
  static Future<void> updateActivity() async {
    await _storage.write(
      key: _keyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }

  // Leer token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Limpiar sesión al cerrar
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}