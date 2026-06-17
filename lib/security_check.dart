import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Verifica si la Depuración USB (ADB) está activa en el dispositivo,
/// consultando directamente Settings.Global.ADB_ENABLED vía MethodChannel.
class SecurityCheck {
  static const _platform = MethodChannel('com.example.logincamara/security');

  /// Devuelve true si ADB está habilitado Y la app NO está en modo debug.
  /// En kDebugMode siempre devuelve false para no estorbar el desarrollo.
  static Future<bool> isAdbDebuggingActive() async {
    // Excepción de entorno de desarrollo: si corres "flutter run" normal,
    // kDebugMode es true y NO se aplica el bloqueo.
    if (kDebugMode) {
      return false;
    }

    try {
      final bool? isAdbEnabled =
      await _platform.invokeMethod<bool>('isAdbEnabled');
      return isAdbEnabled ?? false;
    } catch (_) {
      // Si el canal falla, por seguridad asumimos que no hay riesgo
      // detectado (fail-safe simple para esta práctica).
      return false;
    }
  }
}