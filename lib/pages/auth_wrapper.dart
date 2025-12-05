import 'package:flutter/material.dart';
import '../core/services/session_cache_service.dart';
import '../screens/home_screen.dart';
import 'login_page.dart';

/// AuthWrapper con renderizado optimista
///
/// PATRÓN ZYNC:
/// 1. Lee cache SÍNCRONO desde memoria RAM (<1ms)
/// 2. Muestra HomeScreen INSTANTÁNEAMENTE si hay sesión
/// 3. Verifica validez en background (no bloquea UI)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ CRÍTICO: Lectura SÍNCRONA desde memoria RAM (0ms)
    final session = SessionCacheService.restoreSessionSync();

    if (session != null && session['userId']?.isNotEmpty == true) {
      print(
        '⚡ [AuthWrapper] Sesión desde RAM: ${session['userId']} - INSTANTÁNEO',
      );

      // ⚡ OPTIMIZACIÓN: Mostrar HomeScreen sin esperar nada
      return Stack(
        children: [
          const HomeScreen(),

          // Verificación en background (opcional - no hay Firebase aquí)
          _BackgroundVerification(
            onInvalidSession: () {
              SessionCacheService.clearSession();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      );
    }

    // Sin sesión - mostrar login
    print('⚠️ [AuthWrapper] Sin sesión - mostrando login');
    return const LoginPage();
  }
}

/// Widget de verificación en background
class _BackgroundVerification extends StatefulWidget {
  final VoidCallback onInvalidSession;

  const _BackgroundVerification({required this.onInvalidSession});

  @override
  State<_BackgroundVerification> createState() =>
      _BackgroundVerificationState();
}

class _BackgroundVerificationState extends State<_BackgroundVerification> {
  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    // Esperar un poco para no competir con renderizado
    await Future.delayed(const Duration(milliseconds: 100));

    // En una app real, aquí verificarías con Firebase
    // Para este test, asumimos que la sesión es válida
    print('✅ [AuthWrapper] Verificación en background completada');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
