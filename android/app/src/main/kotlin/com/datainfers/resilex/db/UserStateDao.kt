package com.datainfers.resilex.db

import androidx.room.*

/**
 * DAO para operaciones SQLite
 * 
 * OPERACIONES:
 * - get(): Leer estado actual (sync, <3ms)
 * - insert(): Guardar/actualizar estado (REPLACE on conflict)
 * - clear(): Limpiar estado (logout)
 */
@Dao
interface UserStateDao {
    
    @Query("SELECT * FROM user_state WHERE id = 1 LIMIT 1")
    fun get(): UserStateEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(state: UserStateEntity)
    
    @Query("DELETE FROM user_state")
    fun clear()
}
