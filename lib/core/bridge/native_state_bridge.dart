import 'package:flutter/services.dart';

/// Bridge para comunicación entre Flutter (Dart) y Android (Kotlin)
///
/// Expone funciones del NativeStateManager de Android
///
/// CAPAS DE CACHE:
/// - L1: NativeStateManager (memoria Kotlin) - <1ms
/// - L2: Room SQLite - <3ms (lectura sync)
/// - L3: SessionCacheService (memoria Dart) - 0ms
/// - L4: SharedPreferences - 50-100ms
class NativeStateBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.datainfers.resilex/native_state',
  );

  /// Guardar estado completo en cache nativo (SQLite)
  static Future<void> setUserId({
    required String userId,
    required String email,
    String? circleId,
  }) async {
    try {
      print('📱 [NativeBridge] Guardando en capa nativa: $userId');
      await _channel.invokeMethod('setUserId', {
        'userId': userId,
        'email': email,
        'circleId': circleId ?? '',
      });
      print('✅ [NativeBridge] Guardado en SQLite');
    } catch (e) {
      print('❌ [NativeBridge] Error: $e');
    }
  }

  /// Obtener userId desde cache nativo (síncrono en Kotlin, <1ms)
  static Future<String?> getUserId() async {
    try {
      final result = await _channel.invokeMethod<String>('getUserId');
      print('⚡ [NativeBridge] UserId desde nativo: $result');
      return result;
    } catch (e) {
      print('❌ [NativeBridge] Error obteniendo userId: $e');
      return null;
    }
  }

  /// Obtener email desde cache nativo
  static Future<String?> getEmail() async {
    try {
      final result = await _channel.invokeMethod<String>('getEmail');
      return result;
    } catch (e) {
      print('❌ [NativeBridge] Error obteniendo email: $e');
      return null;
    }
  }

  /// Obtener circleId desde cache nativo
  static Future<String?> getCircleId() async {
    try {
      final result = await _channel.invokeMethod<String>('getCircleId');
      return result;
    } catch (e) {
      print('❌ [NativeBridge] Error obteniendo circleId: $e');
      return null;
    }
  }

  /// Limpiar cache nativo (logout)
  static Future<void> clear() async {
    try {
      print('🧹 [NativeBridge] Limpiando cache nativo');
      await _channel.invokeMethod('clear');
      print('✅ [NativeBridge] Cache nativo limpiado');
    } catch (e) {
      print('❌ [NativeBridge] Error limpiando: $e');
    }
  }
}
