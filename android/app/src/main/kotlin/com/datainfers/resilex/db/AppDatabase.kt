package com.datainfers.resilex.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

/**
 * Room Database para cache local
 * 
 * PROPÓSITO: Almacenamiento SQLite ultra-rápido (<3ms)
 * 
 * VENTAJAS:
 * - Persistencia: Sobrevive a process kill
 * - Velocidad: <3ms de latencia
 * - Thread-safe: Room maneja concurrencia
 * - Tipado: Compile-time safety
 */
@Database(
    entities = [UserStateEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    
    abstract fun userStateDao(): UserStateDao
    
    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null
        
        /**
         * Singleton thread-safe
         * Inicializar con allowMainThreadQueries() para lecturas síncronas
         */
        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "zync_state_db"
                )
                .allowMainThreadQueries() // ⚡ CRÍTICO: Permite lecturas sync (<3ms)
                .build()
                
                INSTANCE = instance
                instance
            }
        }
        
        /**
         * Cerrar base de datos (cleanup)
         */
        fun closeDatabase() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }
}
