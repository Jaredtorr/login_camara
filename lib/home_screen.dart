import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'secure_data_manager.dart';
import 'session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _inactivityTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 60;

  String? _token;
  String? _fcmToken;
  Map<String, String?> _sensitiveData = {};
  bool _dataWiped = false;

  StreamSubscription<RemoteMessage>? _fcmForegroundSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _resetTimer();
    _listenFcmForeground();
  }

  Future<void> _loadData() async {
    final token      = await SecureDataManager.getToken();
    final fcmToken   = await SecureDataManager.getFcmToken();
    final sensitive  = await SecureDataManager.getSensitiveData();
    final hasData    = await SecureDataManager.hasSensitiveData();
    setState(() {
      _token         = token;
      _fcmToken      = fcmToken;
      _sensitiveData = sensitive;
      _dataWiped     = !hasData;
    });
  }

  /// Escuchar mensajes FCM en primer plano para refrescar la UI inmediatamente.
  void _listenFcmForeground() {
    _fcmForegroundSub = FirebaseMessaging.onMessage.listen((msg) async {
      if (msg.data['type'] == 'remote_wipe') {
        // Esperar a que FcmService procese el borrado
        await Future.delayed(const Duration(milliseconds: 300));
        await _loadData();
        if (mounted) _showWipeDialog();
      }
    });
  }

  void _showWipeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Datos eliminados remotamente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text(
          'Se recibió una notificación de borrado remoto.\n'
          'Todos los datos sensibles han sido eliminados del dispositivo.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar',
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    SecureDataManager.updateActivity();
  }

  Future<void> _logoutByInactivity() async {
    await SecureDataManager.clearSession();
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
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _manualLogout() async {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    await SecureDataManager.clearSession();
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
    _fcmForegroundSub?.cancel();
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timer de inactividad ─────────────────────────────
              Center(
                child: Column(
                  children: [
                    const Text('Cierre por inactividad en:',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        color: _secondsRemaining <= 15
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _secondsRemaining <= 15 ? Colors.red : Colors.green,
                        ),
                      ),
                      child: Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _secondsRemaining <= 15 ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Toca la pantalla para reiniciar el timer',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Estado de datos sensibles ────────────────────────
              _SectionCard(
                icon: _dataWiped ? Icons.delete_forever : Icons.security,
                color: _dataWiped ? Colors.red : Colors.deepPurple,
                title: _dataWiped ? '⚠️ Datos sensibles eliminados' : '🔒 Datos Sensibles (Almacén Seguro)',
                children: _dataWiped
                    ? [
                        const Text(
                          'Los datos fueron eliminados mediante notificación remota FCM.',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ]
                    : _sensitiveData.entries.map((e) {
                        return _DataRow(label: e.key, value: e.value ?? '—');
                      }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Token de sesión ──────────────────────────────────
              if (_token != null)
                _SectionCard(
                  icon: Icons.key,
                  color: Colors.teal,
                  title: 'Token de sesión',
                  children: [
                    Text(
                      _token!,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace', color: Colors.teal),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // ── FCM Token ────────────────────────────────────────
              _SectionCard(
                icon: Icons.notifications_active,
                color: Colors.orange,
                title: 'FCM Token (ID del dispositivo)',
                children: [
                  if (_fcmToken != null) ...[
                    Text(
                      _fcmToken!,
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace', color: Colors.orange),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Envía una notificación FCM con:\n'
                        '  "type": "remote_wipe"\n'
                        '  "target_user_id": "admin"\n'
                        'para borrar los datos sensibles de este usuario.',
                        style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                      ),
                    ),
                  ] else
                    const Text('Obteniendo token...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
