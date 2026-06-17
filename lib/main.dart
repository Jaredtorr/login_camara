import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'fcm_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'security_gate.dart';

/// Navigator key global — permite a SecurityGate mostrar diálogos
/// desde fuera del árbol de MaterialApp.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FcmService.init();

  runApp(
    SecurityGate(child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Seguro',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,   // ← clave para que SecurityGate pueda mostrar diálogos
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':     (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
