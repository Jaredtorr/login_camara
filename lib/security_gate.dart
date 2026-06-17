import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'security_check.dart';
import 'main.dart' show navigatorKey;

/// Widget RASP que envuelve TODA la aplicación.
/// Verifica ADB en el arranque Y cada 2 segundos mientras la app vive.
/// También re-verifica cuando la app regresa a primer plano.
/// Usa navigatorKey para mostrar el diálogo desde cualquier pantalla.
class SecurityGate extends StatefulWidget {
  final Widget child;
  const SecurityGate({super.key, required this.child});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {

  bool _initialCheckDone = false;
  bool _dialogShowing    = false;
  Timer? _pollingTimer;

  static const _pollInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Verificación inicial (arranque)
    _runSecurityCheck();
    // Verificación continua mientras la app está activa
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      _pollInterval,
      (_) => _runSecurityCheck(),
    );
  }

  /// Se dispara cuando el usuario regresa desde Ajustes (foreground).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runSecurityCheck();
    }
  }

  Future<void> _runSecurityCheck() async {
    final bool adbActive = await SecurityCheck.isAdbDebuggingActive();

    if (!mounted) return;

    // Marcar verificación inicial como completada
    if (!_initialCheckDone) {
      setState(() => _initialCheckDone = true);
    }

    if (adbActive && !_dialogShowing) {
      _showBlockingDialog();
    }
  }

  void _showBlockingDialog() {
    // Esperar a que el Navigator esté disponible (primer frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || _dialogShowing) return;

      _dialogShowing = true;
      showDialog(
        context: ctx,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Entorno no seguro detectado',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: const Text(
              'Se detectó que la Depuración USB (ADB) está activa '
              'en este dispositivo.\n\n'
              'Por políticas de seguridad, esta aplicación no puede '
              'ejecutarse mientras este modo esté habilitado, ya que '
              'permite herramientas de análisis e ingeniería inversa.\n\n'
              'Para usar la aplicación:\n'
              '1. Ve a Ajustes → Opciones de desarrollador.\n'
              '2. Desactiva "Depuración USB".\n'
              '3. Vuelve a abrir la aplicación.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text(
                  'Cerrar aplicación',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ).then((_) => _dialogShowing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar spinner solo durante la verificación inicial
    if (!_initialCheckDone) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          ),
        ),
      );
    }
    // Una vez verificado, mostrar la app real
    return widget.child;
  }
}
