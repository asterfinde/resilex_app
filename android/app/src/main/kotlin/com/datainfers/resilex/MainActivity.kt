package com.datainfers.resilex

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.datainfers.resilex.NativeStateManager

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "com.datainfers.resilex/native_state"
    private val TAG = "MainActivity"
    
    // Keep-alive state
    private var isKeepAliveRunning = false
    
    // Current user (sincronizado con Flutter)
    private var currentUserId: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "🚀 MainActivity.onCreate()")
        
        // ⚡ CRÍTICO: Inicializar cache nativo al arrancar
        val cacheStart = System.currentTimeMillis()
        NativeStateManager.initCache(this)
        val cacheDuration = System.currentTimeMillis() - cacheStart
        
        // Verificar si hay estado guardado
        currentUserId = NativeStateManager.getUserId(this)
        
        Log.d(TAG, "⚡ Cache nativo: ${cacheDuration}ms | userId: $currentUserId")
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configurar MethodChannel para comunicación Flutter <-> Kotlin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setUserId" -> {
                    try {
                        val userId = call.argument<String>("userId")
                        val email = call.argument<String>("email") ?: ""
                        val circleId = call.argument<String>("circleId") ?: ""
                        
                        if (userId != null && userId.isNotEmpty()) {
                            Log.d(TAG, "📤 [FLUTTER→KOTLIN] Sincronizando userId: $userId")
                            currentUserId = userId
                            NativeStateManager.saveUserState(this, userId, email, circleId)
                            result.success(null)
                        } else {
                            // Logout - limpiar estado
                            Log.d(TAG, "🧹 [FLUTTER→KOTLIN] Limpiando estado (logout)")
                            currentUserId = null
                            NativeStateManager.clear(this)
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error en setUserId: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "getUserId" -> {
                    try {
                        val userId = NativeStateManager.getUserId(this)
                        result.success(userId)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error en getUserId: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "getEmail" -> {
                    try {
                        val email = NativeStateManager.getEmail(this)
                        result.success(email)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error en getEmail: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "getCircleId" -> {
                    try {
                        val circleId = NativeStateManager.getCircleId(this)
                        result.success(circleId)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error en getCircleId: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "clear" -> {
                    try {
                        NativeStateManager.clear(this)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error en clear: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "📱 App minimizada (onPause)")
        
        // Solo iniciar keep-alive si hay un usuario autenticado
        if (currentUserId == null) {
            Log.d(TAG, "⚠️ [NATIVO] No hay usuario autenticado - NO iniciando KeepAliveService")
            return
        }
        
        // 🚀 CRÍTICO: Iniciar keep-alive NATIVO para proteger el proceso
        if (!isKeepAliveRunning) {
            Log.d(TAG, "🟢 [NATIVO] Iniciando keep-alive service desde onPause() para usuario: $currentUserId")
            KeepAliveService.start(this)
            isKeepAliveRunning = true
        }
        
        // 🚀 Guardar estado NATIVO inmediatamente
        currentUserId?.let { userId ->
            Log.d(TAG, "💾 [NATIVO] Guardando estado: $userId")
            NativeStateManager.saveUserState(this, userId)
        }
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "📱 App maximizada (onResume)")
        
        // 🚀 Detener keep-alive al resumir (ya no necesario)
        if (isKeepAliveRunning) {
            Log.d(TAG, "🔴 [NATIVO] Deteniendo keep-alive service desde onResume()")
            KeepAliveService.stop(this)
            isKeepAliveRunning = false
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy() - Activity destruida")
        
        // SIEMPRE mantener keep-alive activo si hay usuario
        if (currentUserId != null && !isKeepAliveRunning) {
            Log.d(TAG, "⚠️ [NATIVO] Keep-alive no estaba corriendo - intentando iniciar desde onDestroy()")
            KeepAliveService.start(this)
        }
    }
    
    // 🚀 CRÍTICO: Interceptar back gesture para MINIMIZAR en vez de CERRAR
    // Esto previene que Android mate el proceso, manteniendo la app instantánea
    override fun onBackPressed() {
        Log.d(TAG, "🔙 [UX] Back gesture interceptado - minimizando en vez de cerrar")
        
        // Minimizar app al background (como presionar HOME)
        // Esto llama a onPause() donde keep-alive se activa
        moveTaskToBack(true)
        
        // NO llamar super.onBackPressed() porque eso cierra la app
        // super.onBackPressed()
    }
}
