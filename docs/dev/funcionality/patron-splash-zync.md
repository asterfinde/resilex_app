# Patrón de Splash Screen ZYNC - 3 Capas

**Fecha de documentación:** 5 de diciembre de 2025  
**Proyecto origen:** ZYNC App  
**Aplicable a:** Cualquier app Flutter con Android  
**Objetivo:** Splash screen profesional con transición suave de nativo → Flutter

---

## 📋 Tabla de Contenidos

1. [Concepto General](#concepto-general)
2. [Las 3 Capas del Splash](#las-3-capas-del-splash)
3. [Arquitectura de Archivos](#arquitectura-de-archivos)
4. [Implementación Paso a Paso](#implementación-paso-a-paso)
5. [Ventajas del Patrón](#ventajas-del-patrón)
6. [Aplicación en RESILEX](#aplicación-en-resilex)

---

## 🎯 Concepto General

El patrón de splash ZYNC implementa una experiencia de inicio fluida mediante **3 capas secuenciales**:

```
Usuario abre app
    ↓
CAPA 1: Splash Nativo (Android) - 2 segundos
    ↓
CAPA 2: Splash Flutter (Animado) - 4 segundos
    ↓
CAPA 3: Ingreso a la App (AuthWrapper/HomeScreen)
```

### **Flujo Temporal**

```
0s ────────────── 2s ────────────── 6s ────────────→
│                 │                 │
│  Splash Nativo  │  Splash Flutter │  App Principal
│  (Android XML)  │  (Animado)      │  (AuthWrapper)
│                 │                 │
└─────────────────┴─────────────────┴────────────────→
```

---

## 🏗️ Las 3 Capas del Splash

### **CAPA 1: Splash Nativo (Android)** ⚡

**Duración:** 2 segundos  
**Tecnología:** Android XML + Kotlin  
**Propósito:** Mostrar algo INMEDIATAMENTE mientras Flutter se inicializa

**Características:**
- ✅ Se muestra ANTES de que Flutter cargue
- ✅ Usa recursos nativos de Android (XML vectorial)
- ✅ No requiere que Flutter esté listo
- ✅ Controlado desde `MainActivity.kt` con `installSplashScreen()`
- ✅ Fondo negro + logo vectorial centrado

**Ventaja clave:** El usuario ve algo en <100ms, no una pantalla blanca.

---

### **CAPA 2: Splash Flutter (Animado)** 🎨

**Duración:** 4 segundos  
**Tecnología:** Flutter Widget con animaciones  
**Propósito:** Transición elegante mientras se completan inicializaciones

**Características:**
- ✅ Animación "breathing effect" (escala + opacidad)
- ✅ Logo dibujado con `CustomPainter`
- ✅ Ejecuta inicializaciones en background (Firebase, cache, etc.)
- ✅ Espera mínimo 4 segundos para efecto visual profesional
- ✅ Transición suave a la app principal

**Ventaja clave:** Tiempo para inicializar servicios sin mostrar pantalla de carga fea.

---

### **CAPA 3: Ingreso a la App** 🚀

**Duración:** Instantánea  
**Tecnología:** Flutter (AuthWrapper/HomeScreen)  
**Propósito:** Mostrar la UI principal de la app

**Características:**
- ✅ AuthWrapper decide si mostrar Login o Home
- ✅ Usa patrón ZYNC para restauración instantánea
- ✅ Carga datos desde caché (RAM → SharedPreferences → SQLite)
- ✅ UI lista en <200ms después del splash

**Ventaja clave:** Usuario entra directamente a la app funcional.

---

## 📁 Arquitectura de Archivos

### **Archivos Android (Nativos)**

```
android/app/src/main/
├── res/
│   ├── drawable/
│   │   ├── splash_complete.xml          # Logo vectorial del splash
│   │   └── launch_background.xml        # Referencia a splash_complete
│   ├── drawable-v21/
│   │   └── launch_background.xml        # Para Android 5.0+
│   └── values/
│       └── styles.xml                   # Tema del splash (LaunchTheme)
├── kotlin/com/datainfers/zync/
│   └── MainActivity.kt                  # Control del splash nativo
└── AndroidManifest.xml                  # Configuración del tema

```

### **Archivos Flutter**

```
lib/
├── main.dart                            # Inicialización rápida de Firebase
└── core/
    └── splash/
        └── splash_screen.dart           # Splash animado de Flutter
```

### **Dependencias**

```yaml
# pubspec.yaml
dependencies:
  # NO se usa flutter_native_splash package
  # Se implementa manualmente para mayor control

dev_dependencies:
  flutter_native_splash: ^2.4.2  # Solo para generar íconos (opcional)
```

---

## 🔧 Implementación Paso a Paso

### **PASO 1: Crear el Logo Vectorial (splash_complete.xml)**

**Ubicación:** `android/app/src/main/res/drawable/splash_complete.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Capa 1: Fondo de color -->
    <item>
        <shape android:shape="rectangle">
            <solid android:color="#000000" />
        </shape>
    </item>

    <!-- Capa 2: Logo vectorial centrado -->
    <item android:gravity="center">
        <vector
            android:width="90dp"
            android:height="90dp"
            android:viewportWidth="100"
            android:viewportHeight="100">
            
            <!-- Aquí va tu logo en formato vector (path) -->
            <!-- Ejemplo: Círculo simple -->
            <path
                android:fillColor="#22d3ee"
                android:pathData="
                    M 50,30
                    a 20,20 0 1,0 0,40
                    a 20,20 0 1,0 0,-40
                    z
                "/>
        </vector>
    </item>
</layer-list>
```

**Notas:**
- Usa vectores (SVG) en lugar de PNG para evitar distorsión
- `gravity="center"` asegura centrado perfecto
- Colores deben coincidir con tu brand

---

### **PASO 2: Configurar launch_background.xml**

**Ubicación:** `android/app/src/main/res/drawable/launch_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@drawable/splash_complete"/>
</layer-list>
```

**También crear para Android 5.0+:**  
`android/app/src/main/res/drawable-v21/launch_background.xml` (mismo contenido)

---

### **PASO 3: Configurar Tema en styles.xml**

**Ubicación:** `android/app/src/main/res/values/styles.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Tema para el splash nativo -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar.Fullscreen">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">true</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
    
    <!-- Tema normal de la app -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

---

### **PASO 4: Configurar AndroidManifest.xml**

**Ubicación:** `android/app/src/main/AndroidManifest.xml`

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleInstance"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Tema que se aplicará después del splash -->
    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme" />
        
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

**Clave:** `android:theme="@style/LaunchTheme"` aplica el splash nativo.

---

### **PASO 5: Controlar Duración en MainActivity.kt**

**Ubicación:** `android/app/src/main/kotlin/com/<company>/<app>/MainActivity.kt`

```kotlin
package com.datainfers.resilex

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        // 🎨 SPLASH: Instalar y controlar el splash screen nativo
        var keepSplashOnScreen = true
        val splashScreen = installSplashScreen()
        
        // Mantener el splash visible por exactamente 2 segundos
        splashScreen.setKeepOnScreenCondition { keepSplashOnScreen }
        
        // Programar que se oculte después de 2 segundos
        Handler(Looper.getMainLooper()).postDelayed({
            keepSplashOnScreen = false
            Log.d(TAG, "🎨 [SPLASH] Splash nativo completado (2s)")
        }, 2000)
        
        super.onCreate(savedInstanceState)
    }
}
```

**Dependencia necesaria en `android/app/build.gradle.kts`:**

```kotlin
dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
}
```

---

### **PASO 6: Crear Splash Animado en Flutter**

**Ubicación:** `lib/core/splash/splash_screen.dart`

```dart
import 'package:flutter/material.dart';

class OptimizedSplashScreen extends StatefulWidget {
  final Future<void> Function() onInitialize;
  final Widget child;

  const OptimizedSplashScreen({
    super.key,
    required this.onInitialize,
    required this.child,
  });

  @override
  State<OptimizedSplashScreen> createState() => _OptimizedSplashScreenState();
}

class _OptimizedSplashScreenState extends State<OptimizedSplashScreen> 
    with TickerProviderStateMixin {
  bool _isReady = false;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de breathing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    _initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // Mostrar splash animado por 4 segundos
      final splashDuration = Future.delayed(const Duration(seconds: 4));

      // Ejecutar inicialización en background
      final initFuture = widget.onInitialize();

      // Esperar a que ambos terminen
      await Future.wait([splashDuration, initFuture]);

      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      print('❌ [SplashScreen] Error: $e');
      if (mounted) {
        setState(() => _isReady = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tu logo aquí
              Icon(
                Icons.circle,
                size: 100,
                color: Color(0xFF22d3ee),
              ),
              SizedBox(height: 20),
              Text(
                "RESILEX",
                style: TextStyle(
                  color: Color(0xFF22d3ee),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### **PASO 7: Integrar en main.dart**

**Ubicación:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/session_cache_service.dart';
import 'core/splash/splash_screen.dart';
import 'pages/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 SOLO inicializaciones críticas y rápidas aquí
  // Ejemplo: Firebase (si es necesario)
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESILEX',
      theme: ThemeData.dark(),
      home: OptimizedSplashScreen(
        onInitialize: () async {
          // Inicializaciones que pueden tardar
          await initializeDateFormatting('es_ES', null);
          await SessionCacheService.init();
          // Otras inicializaciones...
        },
        child: const AuthWrapper(),
      ),
    );
  }
}
```

---

## ✅ Ventajas del Patrón

### **1. Experiencia de Usuario Profesional**
- ✅ No hay pantalla blanca al inicio
- ✅ Transición suave entre capas
- ✅ Animaciones fluidas (breathing effect)
- ✅ Percepción de app rápida y pulida

### **2. Rendimiento Optimizado**
- ✅ Splash nativo se muestra en <100ms
- ✅ Inicializaciones pesadas en background
- ✅ No bloquea el renderizado de Flutter
- ✅ Usuario ve algo mientras carga

### **3. Flexibilidad**
- ✅ Control total sobre duración de cada capa
- ✅ Fácil de personalizar (colores, logo, animaciones)
- ✅ Compatible con cualquier app Flutter
- ✅ No depende de paquetes externos

### **4. Mantenibilidad**
- ✅ Código nativo simple (solo XML + Kotlin básico)
- ✅ Splash Flutter reutilizable
- ✅ Separación clara de responsabilidades
- ✅ Fácil de debuggear

---

## 🎨 Aplicación en RESILEX

### **Adaptaciones Necesarias**

#### **1. Logo Vectorial**
Reemplazar el logo ZYNC por el logo RESILEX en `splash_complete.xml`:

```xml
<!-- Logo RESILEX: Ejemplo con texto estilizado -->
<vector
    android:width="120dp"
    android:height="40dp"
    android:viewportWidth="120"
    android:viewportHeight="40">
    
    <path
        android:fillColor="#22d3ee"
        android:pathData="..." />
</vector>
```

#### **2. Colores**
- Fondo: `#0A0A0A` (negro RESILEX)
- Accent: `#22d3ee` (cyan RESILEX)

#### **3. Duración**
- Splash nativo: 2 segundos (mantener)
- Splash Flutter: 3-4 segundos (ajustar según necesidad)

#### **4. Texto**
Cambiar "ZYNC" por "RESILEX" en el splash Flutter.

---

## 📊 Comparativa: Con vs Sin Patrón

### **Sin Patrón (Flutter por defecto)**
```
0s ────────────── 3s ────────────→
│                 │
│  Pantalla Blanca│  App
│  (Nada)         │
└─────────────────┴────────────────→
```
❌ Mala experiencia  
❌ Parece que la app está rota  
❌ Usuario confundido

### **Con Patrón ZYNC**
```
0s ──── 2s ──── 6s ────────────→
│       │       │
│ Logo  │ Anim  │  App
│ Nativo│ Flutter│
└───────┴───────┴────────────────→
```
✅ Experiencia profesional  
✅ Usuario sabe que está cargando  
✅ Percepción de rapidez

---

## 🔍 Debugging

### **Verificar Splash Nativo**

```bash
# Ver logs de Android
adb logcat | grep "SPLASH"

# Deberías ver:
# 🎨 [SPLASH] Splash nativo completado (2s)
```

### **Verificar Splash Flutter**

```dart
// En splash_screen.dart, agregar logs:
print('🎨 [SplashScreen] Iniciando animación');
print('🎨 [SplashScreen] Inicialización completada');
print('🎨 [SplashScreen] Mostrando app principal');
```

### **Problemas Comunes**

**Problema:** Splash nativo no se muestra  
**Solución:** Verificar que `LaunchTheme` esté en `AndroidManifest.xml`

**Problema:** Splash dura muy poco  
**Solución:** Aumentar delay en `MainActivity.kt` (línea del `postDelayed`)

**Problema:** Logo distorsionado  
**Solución:** Usar vectores (XML) en lugar de PNG

---

## 📚 Referencias

- [Android Splash Screen API](https://developer.android.com/develop/ui/views/launch/splash-screen)
- [Flutter Custom Painter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Material Design - Launch Screen](https://m3.material.io/styles/motion/transitions/transition-patterns#launch-screen)

---

## 📝 Checklist de Implementación

- [ ] Crear `splash_complete.xml` con logo vectorial
- [ ] Crear `launch_background.xml` (normal y v21)
- [ ] Configurar `styles.xml` con `LaunchTheme`
- [ ] Actualizar `AndroidManifest.xml` con tema
- [ ] Agregar dependencia `core-splashscreen` en Gradle
- [ ] Implementar control en `MainActivity.kt`
- [ ] Crear `splash_screen.dart` con animaciones
- [ ] Integrar en `main.dart` con `OptimizedSplashScreen`
- [ ] Probar en dispositivo real
- [ ] Ajustar duraciones según necesidad

---

**Última actualización:** 5 de diciembre de 2025  
**Autor:** Equipo RESILEX  
**Basado en:** Implementación de ZYNC App  
**Licencia:** Uso interno para proyectos datAInfers
