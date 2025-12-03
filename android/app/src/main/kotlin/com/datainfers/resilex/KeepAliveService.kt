package com.datainfers.resilex

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Servicio foreground para mantener el proceso vivo en background
 * 
 * PROPÓSITO: Prevenir que Android mate el proceso cuando la app se minimiza
 * 
 * FUNCIONAMIENTO:
 * - Se inicia cuando la app entra en onPause()
 * - Se detiene cuando la app vuelve a onResume()
 * - Muestra notificación persistente (requerido por Android para foreground services)
 * 
 * RESULTADO: Restauración instantánea (<200ms) al maximizar
 */
class KeepAliveService : Service() {
    
    companion object {
        private const val TAG = "KeepAliveService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "keep_alive_channel"
        
        /**
         * Iniciar servicio foreground
         */
        fun start(context: Context) {
            try {
                val intent = Intent(context, KeepAliveService::class.java)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        context.startForegroundService(intent)
                        Log.d(TAG, "🟢 Keep-alive service iniciado (foreground)")
                    } catch (e: Exception) {
                        // Fallback: intentar como servicio normal
                        Log.w(TAG, "⚠️ No se pudo iniciar foreground service, intentando normal: ${e.message}")
                        context.startService(intent)
                    }
                } else {
                    context.startService(intent)
                    Log.d(TAG, "🟢 Keep-alive service iniciado (normal)")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error iniciando keep-alive: ${e.message}", e)
                // No lanzar excepción - es mejor que la app funcione sin keep-alive
            }
        }
        
        /**
         * Detener servicio foreground
         */
        fun stop(context: Context) {
            try {
                val intent = Intent(context, KeepAliveService::class.java)
                context.stopService(intent)
                Log.d(TAG, "🔴 Keep-alive service detenido")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error deteniendo keep-alive: ${e.message}", e)
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate() - Servicio creado")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand() - Iniciando foreground")
        
        try {
            // Crear notificación y promover a foreground
            createNotificationChannel()
            val notification = buildNotification()
            
            // Iniciar en foreground con manejo de errores
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ requiere especificar tipo
                startForeground(NOTIFICATION_ID, notification)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            
            Log.d(TAG, "✅ Servicio en foreground - proceso protegido")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error iniciando foreground service: ${e.message}", e)
            // Si falla, detener el servicio
            stopSelf()
        }
        
        // START_STICKY: Android reiniciará el servicio si lo mata
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy() - Servicio destruido")
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        // No necesitamos binding
        return null
    }
    
    /**
     * Crear canal de notificación (requerido en Android 8+)
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Keep Alive Service",
                NotificationManager.IMPORTANCE_LOW // Baja importancia = sin sonido
            ).apply {
                description = "Mantiene la app activa en background"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Construir notificación persistente
     */
    private fun buildNotification(): Notification {
        // Intent para abrir la app al tocar la notificación
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Resilex")
            .setContentText("App activa en background")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .setOngoing(true) // No se puede deslizar para cerrar
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }
}
