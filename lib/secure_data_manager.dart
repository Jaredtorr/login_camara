import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestiona todos los datos sensibles del usuario en almacenamiento seguro.
/// Campos sensibles:
///   - nombre_completo   : nombre del usuario
///   - correo_electronico: correo
///   - curp              : Clave Única de Registro de Población
///   - numero_tarjeta    : últimos 4 dígitos de tarjeta
/// Además hereda los campos de sesión: token, login_time, last_activity.
class SecureDataManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Claves de sesión ───────────────────────────────────────────
  static const keyToken        = 'session_token';
  static const keyLoginTime    = 'session_login_time';
  static const keyLastActivity = 'session_last_activity';
  static const keyUserId       = 'user_id';      // para identificar al usuario en FCM
  static const keyFcmToken     = 'fcm_token';    // token de dispositivo FCM

  // ── Claves de datos sensibles ──────────────────────────────────
  static const keyNombre        = 'sensitive_nombre_completo';
  static const keyCorreo        = 'sensitive_correo_electronico';
  static const keyCurp          = 'sensitive_curp';
  static const keyNumTarjeta    = 'sensitive_numero_tarjeta';

  // ── Guardar sesión al hacer login ──────────────────────────────
  static Future<void> saveSession(String token, String userId) async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: keyToken,        value: token);
    await _storage.write(key: keyLoginTime,    value: now);
    await _storage.write(key: keyLastActivity, value: now);
    await _storage.write(key: keyUserId,       value: userId);
  }

  /// Poblar automáticamente datos sensibles de ejemplo al iniciar sesión.
  static Future<void> populateSensitiveData(String username) async {
    await _storage.write(key: keyNombre,     value: 'Juan Carlos $username Pérez');
    await _storage.write(key: keyCorreo,     value: '$username@correo.upchiapas.mx');
    await _storage.write(key: keyCurp,       value: 'PEMJ900315HCHRZN09');
    await _storage.write(key: keyNumTarjeta, value: '**** **** **** 4872');
  }

  // ── Leer token y userId ────────────────────────────────────────
  static Future<String?> getToken()  async => _storage.read(key: keyToken);
  static Future<String?> getUserId() async => _storage.read(key: keyUserId);

  // ── Guardar FCM token ──────────────────────────────────────────
  static Future<void> saveFcmToken(String fcmToken) async {
    await _storage.write(key: keyFcmToken, value: fcmToken);
  }

  static Future<String?> getFcmToken() async => _storage.read(key: keyFcmToken);

  // ── Leer todos los datos sensibles ────────────────────────────
  static Future<Map<String, String?>> getSensitiveData() async {
    return {
      'Nombre':         await _storage.read(key: keyNombre),
      'Correo':         await _storage.read(key: keyCorreo),
      'CURP':           await _storage.read(key: keyCurp),
      'Tarjeta':        await _storage.read(key: keyNumTarjeta),
    };
  }

  // ── Verificar si hay datos sensibles ──────────────────────────
  static Future<bool> hasSensitiveData() async {
    final nombre = await _storage.read(key: keyNombre);
    return nombre != null && nombre.isNotEmpty;
  }

  // ── Actualizar última actividad ────────────────────────────────
  static Future<void> updateActivity() async {
    await _storage.write(
      key: keyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }

  // ── Borrar SOLO datos sensibles (wipe remoto) ─────────────────
  static Future<void> wipeSensitiveData() async {
    await _storage.delete(key: keyNombre);
    await _storage.delete(key: keyCorreo);
    await _storage.delete(key: keyCurp);
    await _storage.delete(key: keyNumTarjeta);
  }

  // ── Borrar todo (logout) ───────────────────────────────────────
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
