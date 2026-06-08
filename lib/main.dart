import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // cambia a false para producción
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Seguro',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true, // requerido por device_preview
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
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