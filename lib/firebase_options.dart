// ARCHIVO GENERADO — reemplaza los valores con los de tu proyecto Firebase.
//
// Pasos para obtener estos valores:
// 1. Ir a https://console.firebase.google.com
// 2. Crear proyecto (o abrir el existente)
// 3. Agregar app Android con packageName: com.example.logincamara
// 4. Descargar google-services.json y colocarlo en android/app/
// 5. En Configuración del proyecto > Tu app, ver los valores SDK
//
// ALTERNATIVA RÁPIDA: instalar FlutterFire CLI y ejecutar:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
// Eso reemplazará este archivo automáticamente.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma. '
          'Ejecuta: flutterfire configure',
        );
    }
  }

  /// ⚠️ REEMPLAZA estos valores con los de tu google-services.json

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDw2BlHg_LDMiMTNnwGlmjSE4aPrSfeB9E',
    appId: '1:666814214352:android:7ee4e17a7cc02f7809eed5',
    messagingSenderId: '666814214352',
    projectId: 'logincamara-fcm',
    storageBucket: 'logincamara-fcm.firebasestorage.app',
  );
}
