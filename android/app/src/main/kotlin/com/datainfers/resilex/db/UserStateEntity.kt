package com.datainfers.resilex.db

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Entidad SQLite para estado de usuario
 * 
 * CAMPOS:
 * - userId: UID de Firebase
 * - email: Email del usuario
 * - circleId: Círculo activo (opcional)
 * - lastSaved: Timestamp de último guardado
 */
@Entity(tableName = "user_state")
data class UserStateEntity(
    @PrimaryKey val id: Int = 1, // Solo guardamos 1 registro
    val userId: String,
    val email: String = "",
    val circleId: String = "",
    val lastSaved: Long = System.currentTimeMillis()
)
