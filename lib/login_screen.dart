import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_manager.dart';
import 'secure_data_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isChecking = false;

  static const _platform = MethodChannel('com.example.logincamara/security');

  Future<bool> _checkMockLocationNow() async {
    try {
      final result = await _platform.invokeMethod<bool>('isMockLocationActive');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isChecking = true);

    try {
      final bool isFake = await _checkMockLocationNow();
      if (!mounted) return;

      if (isFake) {
        _showFakeGpsAlert();
        return;
      }

      // ── Validar credenciales ──────────────────────────────────
      final user = _userController.text.trim();
      final pass = _passwordController.text;

      if (user == 'admin' && pass == '1234') {
        // Generar token y guardar en almacén encriptado
        final token =
            'TOKEN-${user.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
        // Guardar sesión con userId (usamos el nombre de usuario como ID)
        await SecureDataManager.saveSession(token, user);
        // Poblar automáticamente los 4 campos sensibles
        await SecureDataManager.populateSensitiveData(user);

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Usuario o contraseña incorrectos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorAlert(e.toString());
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showFakeGpsAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.gps_off, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Ubicación falsa detectada',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text(
          'Se detectó que estás usando una app de GPS falso '
              '(como Fake GPS by Lexa u similar).\n\n'
              'No puedes iniciar sesión con una ubicación simulada.\n\n'
              'Para continuar:\n'
              '1. Cierra la app de Fake GPS (Stop).\n'
              '2. Vuelve a intentarlo.',
          style: TextStyle(fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido',
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorAlert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Atención'),
          ],
        ),
        content: Text(
          'No fue posible verificar tu ubicación.\n\n$msg\n\n'
              'Activa el GPS y otorga los permisos para continuar.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar',
                style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 32),
              const Text('Iniciar Sesión',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor:
                    Colors.deepPurple.withOpacity(0.5),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Entrar',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Se verifica ubicación real al iniciar sesión',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}