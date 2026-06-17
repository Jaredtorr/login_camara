import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'security_check.dart';
import 'login_screen.dart';

/// Widget "puerta" que se monta ANTES del LoginScreen.
/// Verifica el entorno de seguridad en initState() (verificación temprana)
/// y, si detecta Depuración USB activa fuera de modo debug, bloquea
/// completamente la UI con un AlertDialog persistente y cierra la app.
class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    // Verificación temprana, antes de montar cualquier lógica de negocio.
    _runSecurityCheck();
  }

  Future<void> _runSecurityCheck() async {
    final bool adbActive = await SecurityCheck.isAdbDebuggingActive();

    if (!mounted) return;

    if (adbActive) {
      // Entorno inseguro: congelar pantalla con diálogo persistente.
      _showBlockingDialog();
    } else {
      // Entorno seguro: continuar al login normalmente.
      setState(() => _checking = false);
    }
  }

  void _showBlockingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (_) => PopScope(
        canPop: false, // Tampoco se puede cerrar con el botón "atrás"
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Entorno no seguro detectado',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: const Text(
            'Se detectó que la Depuración USB (ADB) está activa en este '
                'dispositivo.\n\n'
                'Por políticas de seguridad, esta aplicación no puede ejecutarse '
                'mientras este modo esté habilitado, ya que permite herramientas '
                'de análisis e ingeniería inversa.\n\n'
                'Para usar la aplicación:\n'
                '1. Ve a Ajustes → Opciones de desarrollador.\n'
                '2. Desactiva "Depuración USB".\n'
                '3. Vuelve a abrir la aplicación.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cierre limpio y completo de la aplicación.
                SystemNavigator.pop();
              },
              child: const Text(
                'Cerrar aplicación',
                style: TextStyle(
                    color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // Pantalla de carga mientras se verifica el entorno.
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }
    // Entorno seguro confirmado: continuar al flujo normal de la app.
    return const LoginScreen();
  }
}