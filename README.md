# Min Test - Instant App Restoration Demo

Demo de arquitectura de restauración instantánea de aplicación Flutter (<200ms) usando cache multi-capa (Memoria + SQLite + SharedPreferences).

## 🎯 Objetivo

Demostrar cómo restaurar una aplicación Flutter en menos de 200ms después de que Android mate el proceso, siguiendo la arquitectura documentada en `instant-app-restoration-architecture.md` de Zync App.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────┐
│     App Lifecycle (Minimize)       │
└─────────────────┬───────────────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
    ┌───▼───┐ ┌──▼──┐ ┌────▼────┐
    │Memory │ │SQLite│ │SharedP. │
    │  0ms  │ │ 3ms  │ │  50ms   │
    └───────┘ └──────┘ └─────────┘
                  │
        ┌─────────▼─────────┐
        │  Restore (<200ms) │
        └───────────────────┘
```

### Capas de Cache:

1. **Layer 1 - Memoria (Dart)**: 0ms - `SessionCacheService._memoryCache`
2. **Layer 2 - SQLite Nativo (Kotlin)**: <3ms - `NativeStateManager` con Room
3. **Layer 3 - SharedPreferences (Dart)**: 50-100ms - Fallback

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── bridge/
│   │   └── native_state_bridge.dart      # MethodChannel para Kotlin
│   ├── data/
│   │   └── fake_data_generator.dart      # 20 registros fake
│   ├── models/
│   │   └── user_record.dart              # Modelo de datos
│   ├── services/
│   │   └── session_cache_service.dart    # Cache Flutter (Layer 1 + 3)
│   └── utils/
│       └── performance_tracker.dart       # Medición de tiempos
├── pages/
│   ├── auth_wrapper.dart                 # UI optimista con FutureBuilder
│   ├── home_page.dart                    # Vista principal con datos
│   └── login_page.dart                   # Login simple
└── main.dart                             # Lifecycle observer

android/app/src/main/kotlin/com/example/mintest/
├── db/
│   ├── AppDatabase.kt                    # Room Database singleton
│   ├── UserStateDao.kt                   # DAO para queries
│   └── UserStateEntity.kt                # Entidad SQLite
├── min_test/
│   └── MainActivity.kt                   # MethodChannel + initCache()
└── NativeStateManager.kt                 # Cache nativo (Layer 2)
```

## 🚀 Cómo Probar la Restauración Instantánea

### 1. Instalar y Ejecutar

```bash
cd C:\Users\dante\projects\min_test
flutter pub get
flutter run
```

### 2. Hacer Login

- Ingresa cualquier email (ej: `test@example.com`)
- Se guardará el userId en las 3 capas de cache

### 3. Minimizar la App

- Presiona el botón Home del dispositivo/emulador
- Android puede matar el proceso para liberar memoria

### 4. Maximizar la App

- Toca el ícono de "Min Test"
- **Observa los logs de performance**:

```
⏱️ [Performance] App Maximization: XXXms
🎉 [Performance] ✅ Target alcanzado: XXXms < 200ms
```

## 📊 Logs a Observar

### Android (Logcat - Tag: `MainActivity`, `NativeStateManager`)

```
🚀 [MainActivity] onCreate()
🚀 [NativeStateManager] Inicializando cache nativo...
✅ [NativeStateManager] Cache inicializado en 2ms: user_1733247123456
📱 [MainActivity] UserId desde cache: user_1733247123456
📱 [MainActivity] App minimizada (onPause)
📱 [MainActivity] App maximizada (onResume)
```

### Flutter (Console)

```
🚀 [Main] Inicializando app...
🚀 [SessionCache] Inicializando...
✅ [SessionCache] Inicializado en 48ms: user_1733247123456
📱 [Lifecycle] Observer registrado
⚡ [SessionCache] Sesión desde memoria (0ms): user_1733247123456
⚡ [AuthWrapper] Usando sesión cacheada: user_1733247123456
📊 [HomePage] Cargando datos...
✅ [HomePage] Datos cargados en 12ms
📱 [Lifecycle] App minimizada - guardando estado...
✅ [Lifecycle] Estado guardado
📱 [Lifecycle] App maximizada - restaurando...
⏱️ [Performance] App Maximization: 187ms
🎉 [Performance] ✅ Target alcanzado: 187ms < 200ms
```

## 🔧 Datos de Prueba

La app genera 20 registros fake automáticamente con:

- Nombres aleatorios (español)
- Estados con emojis: 🙂 Fine, 🆘 SOS, 📅 Meeting, etc.
- Timestamps aleatorios (últimas 2 horas)

## 📱 Flujo de Restauración

### Cold Start (Proceso Muerto)

```
User tap → MainActivity.onCreate() (5ms)
         → NativeStateManager.initCache() (3ms)
         → SessionCacheService.init() (50ms)
         → AuthWrapper.build() (2ms)
         → SessionCache.restoreSession() (0ms - desde memoria)
         → HomePage renderizado (10ms)
         ────────────────────────────────────
         TOTAL: ~70-200ms ✅
```

### Warm Resume (Proceso Vivo)

```
User tap → MainActivity.onResume() (1ms)
         → AuthWrapper (ya construido)
         → SessionCache desde memoria (0ms)
         ────────────────────────────────────
         TOTAL: ~1-10ms ✅✅
```

## ⚙️ Dependencias

### Flutter (`pubspec.yaml`)

```yaml
dependencies:
  shared_preferences: ^2.2.2
```

### Android (`build.gradle.kts`)

```kotlin
dependencies {
    val roomVersion = "2.6.1"
    implementation("androidx.room:room-runtime:$roomVersion")
    implementation("androidx.room:room-ktx:$roomVersion")
    kapt("androidx.room:room-compiler:$roomVersion")
    
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

## 🎯 Métricas de Éxito

| Escenario | Target | Resultado Esperado |
|-----------|--------|-------------------|
| Cold start (proceso muerto) | <200ms | ✅ 70-200ms |
| Warm resume (proceso vivo) | <10ms | ✅ 0-10ms |
| Lectura SQLite | <3ms | ✅ 1-3ms |
| Lectura memoria | 0ms | ✅ 0ms |

## 📚 Referencias

- Documento base: `zync_app/docs/tec/instant-app-restoration-architecture.md`
- Room Persistence Library: https://developer.android.com/training/data-storage/room
- SharedPreferences: https://pub.dev/packages/shared_preferences

## 🐛 Troubleshooting

### Error: "Room cannot find implementation"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Error: "kapt plugin not found"

Verifica que `build.gradle.kts` tenga:
```kotlin
plugins {
    id("kotlin-kapt")
}
```

### No se ve el userId en logs

- Verifica que hiciste login primero
- Revisa Logcat con filtro `tag:NativeStateManager OR tag:MainActivity`
- Asegúrate que Flutter Console muestra `✅ [SessionCache] Sesión guardada`

---

**Creado por**: Siguiendo arquitectura de Zync App  
**Fecha**: Diciembre 3, 2025  
**Performance Target**: ✅ <200ms de restauración
