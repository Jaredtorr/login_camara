import 'dart:async';
import 'package:flutter/material.dart';
import 'session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _inactivityTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 60; // 1 minuto
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _resetTimer();
  }

  Future<void> _loadToken() async {
    final token = await SessionManager.getToken();
    setState(() => _token = token);
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
      });
    });

    _inactivityTimer = Timer(const Duration(minutes: 1), _logoutByInactivity);

    SessionManager.updateActivity();
  }

  Future<void> _logoutByInactivity() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Sesión expirada',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tu sesión se cerró por inactividad (1 minuto sin interacción).',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text('Volver al Login',
                style: TextStyle(
                    color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _manualLogout() async {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  String get _formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetTimer,
      onPanUpdate: (_) => _resetTimer(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Inicio',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Cerrar sesión',
              onPressed: _manualLogout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 80, color: Colors.deepPurple),
                const SizedBox(height: 24),
                const Text('¡Bienvenido!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (_token != null) ...[
                  const Text('Token de sesión guardado:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _token!,
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.deepPurple),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                const Text('Cierre por inactividad en:',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: _secondsRemaining <= 15
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _secondsRemaining <= 15
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  child: Text(
                    _formattedTime,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining <= 15
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Toca la pantalla para reiniciar el timer',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}