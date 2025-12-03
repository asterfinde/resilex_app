package com.datainfers.resilex

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.datainfers.resilex.db.AppDatabase
import com.datainfers.resilex.db.UserStateEntity

/**
 * Gestor de estado nativo usando SQLite Room
 * 
 * PROPÓSITO: Cache local para restauración instantánea (<3ms)
 * 
 * FUNCIONES:
 * - Guardar userId/email/circleId en SQLite (async, ~5-10ms)
 * - Leer desde cache en memoria (sync, <1ms)
 * - Inicializar cache al abrir MainActivity
 * 
 * VENTAJAS vs SharedPreferences:
 * - Read: <3ms (sync, desde cache de Room)
 * - Write: 5-10ms (async, no bloquea)
 * - Thread-safe
 * - Funciona aunque Flutter crashee
 */
object NativeStateManager {
    private const val TAG = "NativeStateManager"
    
    // Cache en memoria (Layer 1)
    private var cachedState: UserStateEntity? = null
    private var cacheInitialized = false
    
    /**
     * Inicializar cache desde SQLite
     * DEBE llamarse en MainActivity.onCreate()
     */
    fun initCache(context: Context) {
        try {
            val start = System.currentTimeMillis()
            Log.d(TAG, "🚀 Inicializando cache nativo...")
            
            val db = AppDatabase.getInstance(context)
            cachedState = db.userStateDao().get()
            cacheInitialized = true
            
            val duration = System.currentTimeMillis() - start
            Log.d(TAG, "✅ Cache inicializado en ${duration}ms: ${cachedState?.userId}")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error inicializando cache: ${e.message}", e)
        }
    }
    
    /**
     * Guardar estado de usuario
     * 
     * OPTIMIZADO: Actualiza memoria inmediatamente, SQLite async
     */
    fun saveUserState(
        context: Context,
        userId: String,
        email: String = "",
        circleId: String = ""
    ) {
        try {
            val start = System.currentTimeMillis()
            Log.d(TAG, "💾 Guardando estado: $userId")
            
            // 1. Actualizar cache en memoria (0ms)
            val newState = UserStateEntity(
                userId = userId,
                email = email,
                circleId = circleId,
                lastSaved = System.currentTimeMillis()
            )
            cachedState = newState
            
            // 2. Guardar en SQLite (async, no bloquea)
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val db = AppDatabase.getInstance(context)
                    db.userStateDao().insert(newState)
                    
                    val duration = System.currentTimeMillis() - start
                    Log.d(TAG, "✅ Estado guardado en ${duration}ms: $userId")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error guardando en SQLite: ${e.message}", e)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error guardando estado: ${e.message}", e)
        }
    }
    
    /**
     * Obtener userId actual (síncrono, <1ms)
     * 
     * Lee desde cache en memoria - NO accede a disco
     */
    fun getUserId(context: Context): String? {
        if (!cacheInitialized) {
            initCache(context)
        }
        return cachedState?.userId
    }
    
    /**
     * Obtener email actual (síncrono, <1ms)
     */
    fun getEmail(context: Context): String? {
        if (!cacheInitialized) {
            initCache(context)
        }
        return cachedState?.email
    }
    
    /**
     * Obtener circleId actual (síncrono, <1ms)
     */
    fun getCircleId(context: Context): String? {
        if (!cacheInitialized) {
            initCache(context)
        }
        return cachedState?.circleId
    }
    
    /**
     * Obtener estado completo (síncrono, <1ms)
     */
    fun getState(context: Context): UserStateEntity? {
        if (!cacheInitialized) {
            initCache(context)
        }
        return cachedState
    }
    
    /**
     * Verificar si hay estado válido guardado
     */
    fun hasValidState(context: Context): Boolean {
        val userId = getUserId(context)
        return !userId.isNullOrEmpty()
    }
    
    /**
     * Limpiar estado (logout)
     */
    fun clear(context: Context) {
        try {
            Log.d(TAG, "🧹 Limpiando estado nativo")
            
            // 1. Limpiar cache
            cachedState = null
            
            // 2. Limpiar SQLite (async)
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val db = AppDatabase.getInstance(context)
                    db.userStateDao().clear()
                    Log.d(TAG, "✅ Estado limpiado de SQLite")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error limpiando SQLite: ${e.message}", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error limpiando estado: ${e.message}", e)
        }
    }
}
