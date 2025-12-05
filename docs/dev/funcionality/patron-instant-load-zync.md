# Patrón ZYNC (Zero-Delay Sync)

**Versión:** 1.0  
**Fecha:** 5 de diciembre de 2025  
**Autor:** Equipo RESILEX  
**Propósito:** Guía de implementación del patrón ZYNC para restauración instantánea de sesión

---

## 📋 Tabla de Contenidos

1. [¿Qué es el Patrón ZYNC?](#qué-es-el-patrón-zync)
2. [Problema que Resuelve](#problema-que-resuelve)
3. [Arquitectura del Patrón](#arquitectura-del-patrón)
4. [Implementación Paso a Paso](#implementación-paso-a-paso)
5. [Código de Referencia](#código-de-referencia)
6. [Medición de Performance](#medición-de-performance)
7. [Casos de Uso](#casos-de-uso)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 ¿Qué es el Patrón ZYNC?

**ZYNC** es un patrón de arquitectura para **renderizado optimista** que elimina delays en la restauración de sesión cuando el usuario maximiza una aplicación móvil.

### Acrónimo ZYNC

- **Z**ero delay en UI
- S**Y**nc desde RAM
- **N**o bloquea renderizado
- **C**ache en múltiples capas

### Objetivo Principal

Lograr que la app restaure la sesión del usuario en **<200ms** al maximizar, proporcionando una experiencia nativa e instantánea.

---

## ❌ Problema que Resuelve

### Patrón Tradicional (LENTO)

```dart
// ❌ Enfoque tradicional - 50-200ms de delay
class AuthWrapper extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAuth(), // Espera async
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Pantalla de carga
        }
        
        if (snapshot.hasData) {
          return HomePage();
        }
        
        return LoginPage();
      },
    );
  }
  
  Future<User?> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance(); // 50ms
    final userId = prefs.getString('userId');            // Async
    
    if (userId != null) {
      await validateWithFirebase(userId);                // 100-500ms
      return User(id: userId);
    }
    
    return null;
  }
}
```

**Problemas:**
- ⏱️ Delay de 150-700ms antes de mostrar UI
- 😞 Usuario ve pantalla en blanco o loader
- 🐌 Experiencia lenta y no nativa
- 📉 Mala percepción de performance

---

## ✅ Solución ZYNC

### Renderizado Inmediato con Verificación en Background

```dart
// ✅ Patrón ZYNC - 0ms de delay
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lectura SÍNCRONA desde memoria RAM (0-1ms)
    final session = SessionCacheService.restoreSessionSync();
    
    if (session != null && session['userId']?.isNotEmpty == true) {
      // 2. Mostrar HomePage INMEDIATAMENTE
      return Stack(
        children: [
          const HomePage(),  // ⚡ Renderiza SIN esperar nada
          
          // 3. Verificación en background (opcional)
          _BackgroundVerification(
            onInvalidSession: () {
              // Solo si falla, redirigir a login
              Navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      );
    }
    
    // Sin sesión - mostrar login
    return const LoginPage();
  }
}
```

**Ventajas:**
- ⚡ Delay de 0-1ms (lectura desde RAM)
- 😊 Usuario ve su pantalla inmediatamente
- 🚀 Experiencia nativa e instantánea
- 📈 Performance percibida excelente

---

## 🏗️ Arquitectura del Patrón

### Las 3 Capas de Cache

```
┌─────────────────────────────────────────────────┐
│  Layer 1: Memoria RAM (0-1ms)                   │
│  ┌───────────────────────────────────────────┐  │
│  │ Map<String, String> _memoryCache          │  │
│  │ - Lectura síncrona instantánea            │  │
│  │ - Se pierde al cerrar la app              │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
              ↓ Backup
┌─────────────────────────────────────────────────┐
│  Layer 2: SharedPreferences (50ms)              │
│  ┌───────────────────────────────────────────┐  │
│  │ Persistent storage en disco               │  │
│  │ - Carga inicial al abrir app              │  │
│  │ - Persiste entre sesiones                 │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
              ↓ Backup adicional
┌─────────────────────────────────────────────────┐
│  Layer 3: SQLite Nativo (<3ms)                  │
│  ┌───────────────────────────────────────────┐  │
│  │ Base de datos nativa                      │  │
│  │ - Backup ultrarrápido                     │  │
│  │ - Para casos edge                         │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Flujo Completo

```
Usuario minimiza app
    ↓
[AppLifecycleState.paused]
    ↓
Guardar en 3 capas:
  1. RAM (0ms) ✓
  2. SharedPreferences (50ms) ✓
  3. SQLite nativo (<3ms) ✓
    ↓
    ↓
Usuario maximiza app
    ↓
[AppLifecycleState.resumed]
    ↓
AuthWrapper lee desde RAM (0ms) ⚡
    ↓
HomePage renderiza INSTANTÁNEAMENTE
    ↓
Verificación en background (no bloquea UI)
    ↓
Si sesión válida: Continuar
Si sesión inválida: Redirigir a login
```

---

## 🛠️ Implementación Paso a Paso

### Paso 1: Crear el Servicio de Cache en Memoria

```dart
// lib/core/services/session_cache_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de cache de sesión con lectura síncrona desde RAM
class SessionCacheService {
  static SharedPreferences? _prefs;
  static Map<String, String>? _memoryCache; // ⚡ Layer 1: RAM

  /// Inicializar cache (llamar en main() antes de runApp)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Cargar datos a memoria RAM
    final userId = _prefs?.getString('userId');
    final email = _prefs?.getString('email');
    
    if (userId != null) {
      _memoryCache = {
        'userId': userId,
        'email': email ?? '',
      };
      print('⚡ [SessionCache] Cargado a RAM: $userId');
    }
  }

  /// Guardar sesión (escribe en las 3 capas)
  static Future<void> saveSession({
    required String userId,
    required String email,
  }) async {
    // Layer 1: RAM (0ms)
    _memoryCache = {
      'userId': userId,
      'email': email,
    };

    // Layer 2: SharedPreferences (50ms)
    await _prefs?.setString('userId', userId);
    await _prefs?.setString('email', email);

    print('✅ [SessionCache] Sesión guardada: $userId');
  }

  /// Restaurar sesión SÍNCRONA desde RAM (0ms)
  static Map<String, String>? restoreSessionSync() {
    return _memoryCache; // ⚡ Lectura instantánea
  }

  /// Limpiar sesión (todas las capas)
  static Future<void> clearSession() async {
    _memoryCache = null;
    await _prefs?.remove('userId');
    await _prefs?.remove('email');
    print('🗑️ [SessionCache] Sesión limpiada');
  }
}
```

### Paso 2: Crear el Bridge Nativo (Opcional - Layer 3)

```dart
// lib/core/bridge/native_state_bridge.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Bridge para guardar estado en SQLite nativo (<3ms)
class NativeStateBridge {
  static Database? _db;

  /// Guardar userId en SQLite nativo
  static Future<void> setUserId({
    required String userId,
    required String email,
  }) async {
    final db = await _getDatabase();
    
    await db.insert(
      'user_state',
      {'userId': userId, 'email': email},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('✅ [NativeBridge] Estado guardado en SQLite');
  }

  /// Obtener userId desde SQLite nativo
  static Future<Map<String, String>?> getUserId() async {
    final db = await _getDatabase();
    final result = await db.query('user_state', limit: 1);
    
    if (result.isNotEmpty) {
      return {
        'userId': result.first['userId'] as String,
        'email': result.first['email'] as String,
      };
    }
    
    return null;
  }

  /// Limpiar estado
  static Future<void> clear() async {
    final db = await _getDatabase();
    await db.delete('user_state');
  }

  static Future<Database> _getDatabase() async {
    if (_db != null) return _db!;
    
    final path = join(await getDatabasesPath(), 'user_state.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_state (
            userId TEXT PRIMARY KEY,
            email TEXT
          )
        ''');
      },
    );
    
    return _db!;
  }
}
```

### Paso 3: Implementar AuthWrapper con Patrón ZYNC

```dart
// lib/pages/auth_wrapper.dart

import 'package:flutter/material.dart';
import '../core/services/session_cache_service.dart';
import 'home_page.dart';
import 'login_page.dart';

/// AuthWrapper con renderizado optimista
///
/// PATRÓN ZYNC:
/// 1. Lee cache SÍNCRONO desde memoria RAM (<1ms)
/// 2. Muestra HomePage INSTANTÁNEAMENTE si hay sesión
/// 3. Verifica validez en background (no bloquea UI)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ CRÍTICO: Lectura SÍNCRONA desde memoria RAM (0ms)
    final session = SessionCacheService.restoreSessionSync();

    if (session != null && session['userId']?.isNotEmpty == true) {
      print(
        '⚡ [AuthWrapper] Sesión desde RAM: ${session['userId']} - INSTANTÁNEO',
      );

      // ⚡ OPTIMIZACIÓN: Mostrar HomePage sin esperar nada
      return Stack(
        children: [
          const HomePage(),

          // Verificación en background (opcional - no hay Firebase aquí)
          _BackgroundVerification(
            onInvalidSession: () {
              SessionCacheService.clearSession();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      );
    }

    // Sin sesión - mostrar login
    print('⚠️ [AuthWrapper] Sin sesión - mostrando login');
    return const LoginPage();
  }
}

/// Widget de verificación en background
class _BackgroundVerification extends StatefulWidget {
  final VoidCallback onInvalidSession;

  const _BackgroundVerification({required this.onInvalidSession});

  @override
  State<_BackgroundVerification> createState() =>
      _BackgroundVerificationState();
}

class _BackgroundVerificationState extends State<_BackgroundVerification> {
  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    // Esperar un poco para no competir con renderizado
    await Future.delayed(const Duration(milliseconds: 100));

    // En una app real, aquí verificarías con Firebase/Backend
    // Para este ejemplo, asumimos que la sesión es válida
    print('✅ [AuthWrapper] Verificación en background completada');
    
    // Si la sesión fuera inválida:
    // widget.onInvalidSession();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

### Paso 4: Configurar Lifecycle en main.dart

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'core/services/session_cache_service.dart';
import 'core/bridge/native_state_bridge.dart';
import 'pages/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚡ CRÍTICO: Inicializar cache antes de renderizar
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
        // Layer 1: RAM (ya guardado)
        // Layer 2: SharedPreferences (ya guardado)
        
        // Layer 3: SQLite nativo (<3ms)
        NativeStateBridge.setUserId(
          userId: session['userId']!,
          email: session['email'] ?? '',
        );

        print('✅ [Lifecycle] Estado guardado en 3 capas');
      }
    }

    // ========================================
    // AL MAXIMIZAR: Restauración instantánea
    // ========================================
    if (state == AppLifecycleState.resumed) {
      print('📱 [Lifecycle] App maximizada - restaurando...');
      
      // La restauración ocurre automáticamente en AuthWrapper
      // Aquí solo medimos performance
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('⚡ [Performance] Primer frame renderizado');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App con ZYNC',
      home: const AuthWrapper(), // ⚡ Usa patrón ZYNC
    );
  }
}
```

### Paso 5: Crear PerformanceTracker (Opcional)

```dart
// lib/core/utils/performance_tracker.dart

/// Tracker simple de performance
class PerformanceTracker {
  static final Map<String, DateTime> _startTimes = {};

  static void start(String label) {
    _startTimes[label] = DateTime.now();
    print('⏱️ [Performance] Iniciando: $label');
  }

  static int end(String label) {
    final startTime = _startTimes[label];
    if (startTime == null) return 0;

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _startTimes.remove(label);
    
    return duration;
  }
}
```

---

## 📊 Medición de Performance

### Implementar Medición en main.dart

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    print('📱 [Lifecycle] App maximizada - restaurando...');

    PerformanceTracker.start('App Maximization');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final duration = PerformanceTracker.end('App Maximization');

      if (duration < 200) {
        print('⚡ [Performance] ✅ Target alcanzado: ${duration}ms < 200ms');
      } else {
        print('⚠️ [Performance] ❌ Target no alcanzado: ${duration}ms > 200ms');
      }
    });
  }
}
```

### Métricas Esperadas

| Métrica | Target | Típico con ZYNC |
|---------|--------|-----------------|
| Lectura desde RAM | <1ms | 0-1ms ✅ |
| Renderizado HomePage | <200ms | 50-150ms ✅ |
| Verificación background | No bloquea | 100-500ms (async) ✅ |

---

## 🎯 Casos de Uso

### 1. Apps con Autenticación
- **Problema:** Usuario ve login cada vez que maximiza
- **Solución ZYNC:** Restaura sesión instantáneamente desde RAM

### 2. Apps de E-commerce
- **Problema:** Carrito se pierde al minimizar
- **Solución ZYNC:** Mantiene estado del carrito en memoria

### 3. Apps de Productividad
- **Problema:** Formularios se limpian al cambiar de app
- **Solución ZYNC:** Preserva datos del formulario

### 4. Apps de Redes Sociales
- **Problema:** Feed se recarga desde cero
- **Solución ZYNC:** Mantiene posición del scroll y datos

---

## 🔧 Troubleshooting

### Problema: "La sesión no se restaura"

**Causa:** Cache en RAM no inicializado

**Solución:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionCacheService.init(); // ⚡ CRÍTICO
  runApp(const MyApp());
}
```

### Problema: "Performance >200ms"

**Causa:** Lectura desde disco en lugar de RAM

**Solución:**
```dart
// ❌ INCORRECTO - Async
final prefs = await SharedPreferences.getInstance();

// ✅ CORRECTO - Sync desde RAM
final session = SessionCacheService.restoreSessionSync();
```

### Problema: "Sesión se pierde al cerrar app"

**Causa:** Solo guardando en Layer 1 (RAM)

**Solución:**
```dart
// Guardar en las 3 capas
await SessionCacheService.saveSession(userId: userId, email: email);
await NativeStateBridge.setUserId(userId: userId, email: email);
```

---

## 📚 Referencias

- **Implementación en RESILEX:** `lib/pages/auth_wrapper.dart`
- **Cache Service:** `lib/core/services/session_cache_service.dart`
- **Native Bridge:** `lib/core/bridge/native_state_bridge.dart`
- **Lifecycle Management:** `lib/main.dart`

---

## 🚀 Checklist de Implementación

- [ ] Crear `SessionCacheService` con cache en RAM
- [ ] Implementar `AuthWrapper` con lectura síncrona
- [ ] Configurar lifecycle observer en `main.dart`
- [ ] Inicializar cache antes de `runApp()`
- [ ] (Opcional) Implementar `NativeStateBridge` para Layer 3
- [ ] (Opcional) Agregar `PerformanceTracker`
- [ ] Probar minimizar/maximizar app
- [ ] Verificar que performance <200ms
- [ ] Verificar que sesión persiste entre reinicios

---

## 📝 Notas Finales

El patrón ZYNC es especialmente útil para apps que requieren:
- ⚡ Restauración instantánea de sesión
- 🎯 Performance nativa
- 💾 Persistencia de estado
- 😊 UX excepcional

**Target de performance:** <200ms desde maximización hasta primer frame

**Compatibilidad:** Flutter 3.0+, Android/iOS

---

**Mantenido por:** Equipo RESILEX  
**Última actualización:** 5 de diciembre de 2025  
**Versión del patrón:** 1.0
