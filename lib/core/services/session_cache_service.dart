import 'package:shared_preferences/shared_preferences.dart';

/// Cache dual (memoria + disco) para sesión de usuario
///
/// PROPÓSITO: Restauración instantánea (<50ms) desde cache local
///
/// CAPAS:
/// - Layer 1: Memoria RAM (_memoryCache) - 0ms
/// - Layer 2: SharedPreferences (disco) - 50-100ms
class SessionCacheService {
  // Cache en memoria (Layer 1)
  static Map<String, String>? _memoryCache;
  static SharedPreferences? _prefsInstance;

  /// Inicializar al arrancar la app
  static Future<void> init() async {
    try {
      final start = DateTime.now();
      print('🚀 [SessionCache] Inicializando...');

      _prefsInstance = await SharedPreferences.getInstance();

      // Pre-cargar cache desde disco a memoria
      final userId = _prefsInstance!.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        _memoryCache = {
          'userId': userId,
          'email': _prefsInstance!.getString('email') ?? '',
          'lastSave': _prefsInstance!.getString('lastSave') ?? '',
        };
      }

      final duration = DateTime.now().difference(start).inMilliseconds;
      print('✅ [SessionCache] Inicializado en ${duration}ms: $userId');
    } catch (e) {
      print('❌ [SessionCache] Error en init: $e');
    }
  }

  /// Guardar sesión (memoria + disco)
  static Future<void> saveSession({required String userId, required String email}) async {
    try {
      final start = DateTime.now();
      print('💾 [SessionCache] Guardando sesión: $userId');

      // 1. Actualizar memoria inmediatamente (0ms)
      _memoryCache = {'userId': userId, 'email': email, 'lastSave': DateTime.now().toIso8601String()};

      // 2. Persistir a disco (async)
      await _prefsInstance?.setString('userId', userId);
      await _prefsInstance?.setString('email', email);
      await _prefsInstance?.setString('lastSave', DateTime.now().toIso8601String());

      final duration = DateTime.now().difference(start).inMilliseconds;
      print('✅ [SessionCache] Sesión guardada en ${duration}ms');
    } catch (e) {
      print('❌ [SessionCache] Error guardando: $e');
    }
  }

  /// Restaurar sesión (síncrono - 0ms desde memoria)
  static Map<String, String>? restoreSessionSync() {
    return _memoryCache;
  }

  /// Restaurar sesión (asíncrono - fallback a disco)
  static Future<Map<String, String>?> restoreSession() async {
    try {
      final start = DateTime.now();

      // 1. Intentar desde memoria primero
      if (_memoryCache != null && _memoryCache!.isNotEmpty) {
        final duration = DateTime.now().difference(start).inMilliseconds;
        print('⚡ [SessionCache] Sesión desde memoria (${duration}ms): ${_memoryCache!['userId']}');
        return _memoryCache;
      }

      // 2. Fallback a SharedPreferences
      final prefs = _prefsInstance ?? await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        print('⚠️ [SessionCache] No hay sesión guardada');
        return null;
      }

      // 3. Cachear en memoria para próximas llamadas
      _memoryCache = {
        'userId': userId,
        'email': prefs.getString('email') ?? '',
        'lastSave': prefs.getString('lastSave') ?? '',
      };

      final duration = DateTime.now().difference(start).inMilliseconds;
      print('⚡ [SessionCache] Sesión desde disco (${duration}ms): $userId');

      return _memoryCache;
    } catch (e) {
      print('❌ [SessionCache] Error restaurando: $e');
      return null;
    }
  }

  /// Limpiar sesión (logout)
  static Future<void> clearSession() async {
    try {
      print('🧹 [SessionCache] Limpiando sesión');
      _memoryCache = null;
      await _prefsInstance?.clear();
      print('✅ [SessionCache] Sesión limpiada');
    } catch (e) {
      print('❌ [SessionCache] Error limpiando: $e');
    }
  }
}
