import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'secure_data_manager.dart';

/// Handler para mensajes FCM recibidos en BACKGROUND / TERMINATED.
/// Debe ser una función de nivel superior (no un método de clase).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] type=${message.data['type']}  '
      'target=${message.data['target_user_id']}');
  await _processPotentialWipe(message);
}

/// Lógica central de borrado remoto.
/// La notificación DEBE contener en su payload de datos:
///   type          : "remote_wipe"
///   target_user_id: <userId del usuario a limpiar>
Future<void> _processPotentialWipe(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] != 'remote_wipe') return;

  final storedUserId = await SecureDataManager.getUserId();
  final targetUserId = data['target_user_id'];

  // Solo actuar si la notificación está dirigida específicamente a este usuario
  if (storedUserId == null || storedUserId.isEmpty) return;
  if (targetUserId != storedUserId) return;

  debugPrint('[FCM] ✅ Remote wipe confirmado para usuario: $storedUserId');
  await SecureDataManager.wipeSensitiveData();
}

/// Servicio FCM: inicializa, pide permisos y configura handlers.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Inicializar Firebase Messaging.
  /// Llamar una vez después de Firebase.initializeApp().
  static Future<void> init() async {
    // Handler para mensajes en background (debe registrarse antes de runApp)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Solicitar permisos (necesario en iOS y Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permisos: ${settings.authorizationStatus}');

    // Obtener y guardar el FCM token del dispositivo
    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      await SecureDataManager.saveFcmToken(fcmToken);
      debugPrint('[FCM] Token: $fcmToken');
    }

    // Actualizar token cuando Firebase lo renueve
    _messaging.onTokenRefresh.listen((newToken) async {
      await SecureDataManager.saveFcmToken(newToken);
      debugPrint('[FCM] Token renovado: $newToken');
    });

    // Handler para mensajes recibidos con la app en PRIMER PLANO
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM Foreground] type=${message.data['type']}');
      await _processPotentialWipe(message);
    });

    // Handler cuando el usuario toca una notificación y la app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('[FCM OpenedApp] type=${message.data['type']}');
      await _processPotentialWipe(message);
    });
  }

  /// Obtener el FCM token guardado (para mostrarlo en la UI o enviarlo al servidor).
  static Future<String?> getStoredFcmToken() =>
      SecureDataManager.getFcmToken();
}
