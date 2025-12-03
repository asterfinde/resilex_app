import 'package:flutter/material.dart';
import 'core/services/session_cache_service.dart';
import 'core/bridge/native_state_bridge.dart';
import 'core/utils/performance_tracker.dart';
import 'pages/auth_wrapper.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print(' [Main] Inicializando app...');

  // Inicializar cache antes de renderizar
  await SessionCacheService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print(' [Lifecycle] Observer registrado');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ========================================
    // AL MINIMIZAR: Guardar en múltiples capas
    // ========================================
    if (state == AppLifecycleState.paused) {
      print('📱 [Lifecycle] App minimizada - guardando estado...');

      // Obtener sesión actual y guardar en ambas capas
      final session = SessionCacheService.restoreSessionSync();
      if (session != null && session['userId']?.isNotEmpty == true) {
        // Layer 1: SQLite nativo (<3ms)
        NativeStateBridge.setUserId(
          userId: session['userId']!,
          email: session['email'] ?? '',
        );

        // Layer 2: SharedPreferences (50ms) - ya guardado por SessionCache
        print('✅ [Lifecycle] Estado guardado en capa nativa');
      }

      print('✅ [Lifecycle] Estado guardado');
    }

    // ========================================
    // AL MAXIMIZAR: Medir performance
    // ========================================
    if (state == AppLifecycleState.resumed) {
      print('📱 [Lifecycle] App maximizada - restaurando...');

      PerformanceTracker.start('App Maximization');

      // La restauración ocurre en AuthWrapper
      // Aquí solo medimos el tiempo hasta primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final duration = PerformanceTracker.end('App Maximization');

        if (duration < 200) {
          print('⚡ [Performance] ✅ Target alcanzado: ${duration}ms < 200ms');
        } else {
          print(
            '⚠️ [Performance] ❌ Target no alcanzado: ${duration}ms > 200ms',
          );
        }
      });
    }

    if (state == AppLifecycleState.inactive) {
      print('📱 [Lifecycle] App inactiva');
    }

    if (state == AppLifecycleState.detached) {
      print('📱 [Lifecycle] App detached');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Min Test - Instant Restoration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00BFA5),
          secondary: const Color(0xFF00BFA5),
        ),
      ),
      themeMode: ThemeMode.dark, // Forzar tema oscuro
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
