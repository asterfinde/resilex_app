# RESILEX - Concepto del MVP y Funcionalidades

**Fecha de definición:** 2 de diciembre de 2025  
**Versión del documento:** 2.0  
**Estado:** ✅ MVP COMPLETADO - En rama `feature/mvp-ocr-flow`  
**Última actualización:** 5 de diciembre de 2025

---

## 📋 Tabla de Contenidos

1. [Concepto del Producto](#concepto-del-producto)
2. [Propuesta de Valor](#propuesta-de-valor)
3. [Target y Problema](#target-y-problema)
4. [Diferenciación vs Competencia](#diferenciación-vs-competencia)
5. [Funcionalidades del MVP](#funcionalidades-del-mvp)
6. [Arquitectura Técnica](#arquitectura-técnica)
7. [Roadmap](#roadmap)

---

## 🎯 Concepto del Producto

### **Definición**
**RESILEX** es un digitalizador automático de comprobantes Yape/Plin que genera registros de ventas para PyMEs mediante OCR inteligente.

### **Elevator Pitch**
> "La app que digitaliza tus comprobantes Yape/Plin con un click y te genera un CSV para tu contador"

### **NO es:**
- ❌ Un gestor financiero completo (como Budgence)
- ❌ Un sistema de contabilidad
- ❌ Una app de categorización manual de gastos
- ❌ Un competidor de apps bancarias

### **SÍ es:**
- ✅ Un OCR especializado en billeteras digitales peruanas
- ✅ Un registro automático de ventas/ingresos
- ✅ Un generador de reportes CSV para contadores
- ✅ Una herramienta de productividad para PyMEs

---

## 💡 Propuesta de Valor

### **Problema que resuelve**
Las PyMEs que reciben pagos vía Yape/Plin:
- Pierden control de sus ingresos diarios
- No tienen registro organizado de transacciones
- Gastan tiempo transcribiendo manualmente datos
- No pueden generar reportes rápidos para contadores

### **Solución RESILEX**
1. Usuario toma foto del comprobante Yape/Plin
2. OCR extrae automáticamente: merchant, monto, fecha, operación
3. Parser identifica tipo (Yape/Plin/Boleta) sin intervención
4. Guarda en base de datos local (SQLite)
5. Genera CSV para exportar a contador

### **Beneficio principal**
**Automatización 100%**: De foto a CSV en 3 segundos, sin edición manual.

---

## 👥 Target y Problema

### **Usuario objetivo**
- **Segmento:** PyMEs peruanas (negocios informales a pequeños formales)
- **Tamaño:** 1-10 empleados
- **Sector:** Comercio, servicios, emprendimientos
- **Características:**
  - Reciben pagos vía Yape/Plin frecuentemente (5-50 transacciones/día)
  - No usan software de contabilidad formal
  - Necesitan llevar registro para contador o declaraciones
  - Tienen smartphone Android/iOS

### **Pain Points**
1. **Pérdida de control:** "No sé cuánto vendí esta semana"
2. **Tiempo perdido:** Transcribir manualmente 20 tickets toma 1 hora
3. **Errores:** Transcripción manual genera errores numéricos
4. **Desorganización:** Screenshots de Yape en galería mezclados con fotos personales
5. **Presión fiscal:** Necesitan reportes rápidos para contador

---

## ⚖️ Diferenciación vs Competencia

### **RESILEX vs BUDGENCE**

| Aspecto | Budgence | RESILEX MVP |
|---------|----------|-------------|
| **Propósito** | Gestor de gastos personales | Registro de ventas para PyMEs |
| **Input** | Galería → OCR → **Edición manual obligatoria** | Galería → OCR → **Parsing automático 100%** |
| **Categorías** | Funcionales creadas por usuario: "Comida", "Transporte" | Tipos auto-detectados: Yape, Plin, Boleta |
| **Decisión del usuario** | Usuario elige categoría manualmente | OCR detecta tipo automáticamente |
| **Color/Icon** | Usuario personaliza por categoría | Fijo por tipo de comprobante |
| **Storage** | Firebase (cloud) | SQLite (local) |
| **Target** | Personas (control de gastos) | PyMEs (registro de ingresos) |
| **Edición** | Siempre manual (parte del flujo) | Solo si OCR falló (excepción) |
| **Complejidad** | Alta (multi-feature) | Baja (una cosa bien hecha) |

### **Ventaja competitiva**
- **Parsing inteligente automático:** No hay otra app que detecte Yape/Plin sin configuración
- **Especialización:** Solo comprobantes peruanos (Yape, Plin, Boletas SUNAT)
- **Velocidad:** De foto a registro en 3 segundos
- **Simplicidad:** Una función core ejecutada perfectamente

---

## ✨ Funcionalidades del MVP

### **INCLUIDAS (v1.0)**

#### 1. **OCR y Parseo Automático**
- ✅ Reconocimiento de texto con Google ML Kit
- ✅ Estrategias de parseo:
  - `YapeParsingStrategy`: Detecta "¡Yapeaste!" y parsea formato Yape
  - `PlinStrategy`: Detecta "plin" + "Operación exitosa"
  - `BoletaElectronicaStrategy`: Detecta RUC + "Boleta"
  - `ClaudeParsingStrategy`: Fallback genérico
- ✅ Auto-detección de tipo sin intervención del usuario
- ✅ Extracción automática:
  - Merchant (comercio/cliente)
  - Amount (monto)
  - Date (fecha en formato dd/MM/yyyy)
  - Time (hora)
  - Operation Number (número de operación)
  - Type (yape/plin/boleta)

#### 2. **Storage Local (SQLite)**
- ✅ Base de datos embebida (sin conexión requerida)
- ✅ Tabla `receipts` con campos:
  ```sql
  - id (auto-increment)
  - receipt_id (TEXT UNIQUE) - ID alfanumérico: <type><operationNumber>
  - merchant
  - amount
  - date
  - time
  - type (yape/plin/boleta)
  - operation_number
  - description
  - created_at
  - updated_at
  ```
- ✅ Índices optimizados para queries rápidas:
  - `idx_receipt_id`: Búsqueda por ID único
  - `idx_date`: Ordenamiento por fecha
  - `idx_type`: Filtrado por tipo
  - `idx_created_at`: Optimización de carga inicial
- ✅ Detección automática de duplicados por `operation_number`
- ✅ CRUD completo:
  - `insertReceipt()`: Guardar nuevo comprobante (retorna -1 si duplicado)
  - `getAllReceipts()`: Listar todos (optimizado con índice created_at)
  - `getReceiptsByMonth()`: Filtrar por mes
  - `getReceiptsByDateRange()`: Filtrar por rango
  - `updateReceipt()`: Editar comprobante
  - `deleteReceipt()`: Eliminar comprobante

#### 3. **HomeScreen - Lista de Comprobantes**
- ✅ Carga automática desde SQLite (optimizada con `addPostFrameCallback`)
- ✅ Lista agrupada por meses en español (ej: "Diciembre 2025", "Noviembre 2025")
- ✅ Totales mensuales mostrados en cada sección
- ✅ Ordenamiento descendente (más recientes primero)
- ✅ Diseño dark mode profesional:
  - Círculos de color por tipo:
    - Yape: Morado #6B21A8
    - Plin: Verde #267a3e
    - Boleta: Blanco
  - Merchant name
  - Amount con formato S/ 1,234.56
  - Fecha y hora
- ✅ Pull-to-refresh para recargar desde DB
- ✅ Loading indicator durante carga inicial
- ✅ Empty state: "Sin comprobantes registrados"
- ✅ FloatingActionButton (+) centrado en la parte inferior
- ✅ Botones en AppBar:
  - Ícono de backup (☁️) para crear respaldo
  - Ícono de exportación (📥) para generar CSV
- ✅ Restauración instantánea <200ms con patrón ZYNC
- ✅ Inicialización de locale español para DateFormat

#### 4. **ImagePickerScreen - Captura/Selección**
- ✅ Selección desde galería (múltiples imágenes)
- ✅ Captura con cámara
- ✅ Preview de imágenes seleccionadas
- ✅ Procesamiento automático con OCR
- ✅ **Auto-guardado en SQLite** después de parseo
- ✅ Progreso de procesamiento (X/Y imágenes)
- ✅ Mensaje de confirmación: "X comprobantes guardados"
- ✅ Retorna a HomeScreen con refresh automático

#### 5. **ExportSelectionScreen - Selección de Período para CSV**
- ✅ Pantalla de selección de mes/año para exportar
- ✅ Opciones de filtro:
  - **Exportar todos:** Botón destacado con total de comprobantes
  - **Exportar por mes:** Lista de meses disponibles con:
    - Nombre del mes en español
    - Cantidad de comprobantes
    - Total del mes en S/
- ✅ Navegación a ExportScreen con filtro aplicado
- ✅ Diseño consistente con el resto de la app

#### 6. **ExportScreen - Generación de CSV**
- ✅ Generación de CSV con formato estándar:
  ```csv
  Fecha,Hora,Comercio,Monto,Número de Operación,Descripción,Tipo
  02/12/2025,14:30,Bodega San Juan,45.50,y56854,Pago por productos,yape
  ```
- ✅ Guardado en directorio de documentos con timestamp único
- ✅ Nombre de archivo: `resilex_export_DDMMYYYY_HHMM.csv`
- ✅ Botón "Compartir" para enviar CSV (WhatsApp, email, Drive, etc.)
- ✅ Mensaje de éxito con cantidad de comprobantes exportados
- ✅ Muestra mes seleccionado en el título si aplica
- ✅ Recarga automática del HomeScreen al regresar

#### 7. **BackupSelectionScreen - Sistema de Respaldo** 🆕
- ✅ Pantalla de selección de período para backup
- ✅ Opciones de respaldo:
  - **Respaldar todos:** Botón destacado con total de comprobantes
  - **Respaldar por mes:** Lista de meses con estadísticas
- ✅ Generación de archivo ZIP con:
  - `comprobantes.csv`: Datos tabulares
  - `metadata.json`: Resumen y estadísticas del backup
- ✅ Compartir vía share_plus (Email, Drive, WhatsApp, etc.)
- ✅ Nombre de archivo: `resilex_backup_<mes>_YYYYMMDD_HHMMSS.zip`
- ✅ Indicador de progreso durante creación del ZIP
- ✅ Limpieza automática de archivos temporales
- ✅ Notificación con tamaño del archivo y cantidad de comprobantes
- ✅ Sin encriptación (MVP simple, mejora futura en roadmap)

#### 8. **UI/UX**
- ✅ Dark mode (#0A0A0A background, #1A1A1A cards)
- ✅ Color scheme: Cyan #22d3ee (accent)
- ✅ Colores por tipo de comprobante (actualizados):
  - Yape: Morado #6B21A8 (fijo)
  - Plin: Verde #267a3e (fijo) 🆕
  - Boleta: Blanco (fijo)
- ✅ Tipografía: FontWeight.w500 (no bold excesivo)
- ✅ Loading states y error handling
- ✅ SnackBars informativos
- ✅ FloatingActionButton centrado en la parte inferior 🆕
- ✅ Iconografía consistente (Material Icons)
- ✅ Transiciones suaves entre pantallas

#### 9. **Patrón ZYNC - Restauración Instantánea** 🆕
- ✅ Sistema de caché multi-capa:
  - Layer 1: Memoria RAM (0ms)
  - Layer 2: SharedPreferences (50-100ms)
  - Layer 3: SQLite (100-200ms)
- ✅ Restauración de sesión <200ms
- ✅ Optimización con `addPostFrameCallback` para no bloquear UI
- ✅ Inicialización de locale español en `main.dart`
- ✅ Queries optimizadas con índices en SQLite
- ✅ Documentación completa en `docs/dev/funcionality/patron_zync.md`

### **EXCLUIDAS DELIBERADAMENTE (v1.0)**

#### ❌ Autenticación/Login
- **Razón:** No necesaria para MVP con storage local
- **Cuándo:** v1.5 cuando se agregue sync en cloud

#### ❌ Firebase/Cloud Storage
- **Razón:** SQLite local es suficiente para MVP
- **Cuándo:** v2.0 para backup y multi-dispositivo

#### ❌ CRUD de Categorías Personalizadas
- **Razón:** Los tipos están definidos por el comprobante mismo
- **Cuándo:** Nunca - va contra el concepto de auto-detección

#### ❌ Gráficos/Analytics
- **Razón:** No es core para MVP, agrega complejidad
- **Cuándo:** v2.0 para versión premium

#### ❌ Modo Silent/Notificaciones
- **Razón:** Nice-to-have, no core
- **Cuándo:** v1.5

#### ❌ Export a Excel
- **Razón:** CSV es suficiente para MVP (freemium)
- **Cuándo:** v2.0 como feature premium

---

## 🏗️ Arquitectura Técnica

### **Stack Tecnológico**

```
Frontend:
├── Flutter 3.10.0
├── Dart SDK
└── Material Design 3

OCR & Parsing:
├── google_mlkit_text_recognition: ^0.13.1
├── receipt_parser (paquete local)
│   ├── YapeParsingStrategy
│   ├── PlinStrategy
│   ├── BoletaElectronicaStrategy
│   └── ClaudeParsingStrategy

Storage:
├── sqflite: ^2.3.0 (SQLite embebido)
├── path: ^1.8.3
└── path_provider: ^2.1.5

Export/Share:
├── csv: ^6.0.0
├── share_plus: ^10.0.3
└── archive: ^3.4.10 (creación de archivos ZIP)

Utils:
├── intl: ^0.19.0 (formateo de fechas/números)
└── shared_preferences: ^2.5.3 (caché de sesión - patrón ZYNC)
```

### **Patrón de Arquitectura**

```
lib/
├── main.dart                 # Entry point + inicialización locale español
├── screens/
│   ├── home_screen.dart      # Lista agrupada por meses (desde SQLite)
│   ├── image_selection_screen.dart  # Captura/selección de imágenes
│   ├── image_processing_screen.dart # Preview y procesamiento OCR
│   ├── export_selection_screen.dart # Selección de mes para CSV
│   ├── export_screen.dart    # Generación y compartir CSV
│   └── backup_selection_screen.dart # Selección de mes para backup ZIP
├── services/
│   ├── database_service.dart # CRUD SQLite + detección duplicados
│   ├── csv_exporter_service.dart  # Generación CSV
│   └── backup_service.dart   # Generación ZIP + metadata
├── core/
│   ├── services/
│   │   └── session_cache_service.dart # Patrón ZYNC
│   ├── bridge/
│   │   └── native_state_bridge.dart   # Persistencia nativa
│   └── utils/
│       └── performance_tracker.dart   # Métricas de rendimiento
├── pages/
│   ├── auth_wrapper.dart     # Punto de entrada con ZYNC
│   └── login_page.dart       # Login simulado
└── widgets/
    └── ticket_list_item.dart # Componente de lista con colores por tipo

packages/receipt_parser/
├── lib/
│   ├── receipt_parser.dart   # API principal
│   ├── models/
│   │   └── receipt_data.dart
│   ├── services/
│   │   └── parser_service.dart  # Orquestador de estrategias
│   └── strategies/
│       ├── parsing_strategy.dart  # Interface
│       ├── yape_parsing_strategy.dart
│       ├── plin_strategy.dart
│       ├── boleta_electronica_strategy.dart
│       └── claude_parsing_strategy.dart
```

### **Flujo de Datos**

```
Usuario selecciona imagen
         ↓
ImagePickerScreen
         ↓
Google ML Kit OCR (extrae texto)
         ↓
ParserService evalúa estrategias:
  1. YapeParsingStrategy.canParse()
  2. PlinStrategy.canParse()
  3. BoletaElectronicaStrategy.canParse()
  4. ClaudeParsingStrategy.canParse() [fallback]
         ↓
Estrategia seleccionada parsea texto
         ↓
ReceiptData (merchant, amount, date, type, etc.)
         ↓
DatabaseService.insertReceipt() → SQLite
         ↓
Navigator.pop(true) → HomeScreen
         ↓
HomeScreen._loadTicketsFromDB() → Actualiza lista
```

### **Esquema de Base de Datos**

```sql
CREATE TABLE receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receipt_id TEXT NOT NULL UNIQUE,  -- ID alfanumérico: <type><operationNumber>
  merchant TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,           -- Formato: "dd/MM/yyyy"
  time TEXT,                    -- Formato: "HH:mm"
  type TEXT NOT NULL,           -- "yape" | "plin" | "boleta"
  operation_number TEXT,
  description TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Índices optimizados
CREATE INDEX idx_receipt_id ON receipts(receipt_id);
CREATE INDEX idx_date ON receipts(date DESC);
CREATE INDEX idx_type ON receipts(type);
CREATE INDEX idx_created_at ON receipts(created_at DESC);

-- Detección de duplicados
-- El campo operation_number se usa para validar duplicados antes de insertar
-- Si existe un receipt con el mismo operation_number, insertReceipt() retorna -1
```

---

## 🗺️ Roadmap

### **MVP v1.0 - "El Digitalizador"** ✅ [COMPLETADO]
**Objetivo:** Probar concepto con PyMEs

**Features implementadas:**
- ✅ OCR Yape/Plin/Boletas con Google ML Kit
- ✅ Storage SQLite local con índices optimizados
- ✅ Detección automática de duplicados
- ✅ Export CSV por mes o completo
- ✅ Sistema de backup ZIP con metadata
- ✅ UI dark mode profesional
- ✅ Patrón ZYNC para restauración instantánea <200ms
- ✅ Agrupación por meses en español
- ✅ Compartir vía share_plus (Email, Drive, WhatsApp)
- ✅ ID alfanumérico único por comprobante
- ✅ Flujo unidireccional: Foto → SQLite → CSV/ZIP → Contador

**Éxito:** 100 PyMEs usando la app diariamente

**Documentación:**
- `docs/dev/funcionality/patron_zync.md` - Patrón de restauración instantánea
- `docs/dev/funcionality/backup_system.md` - Sistema de respaldo
- `BRANCHING_STRATEGY.md` - Trunk Based Software Development

---

### **v1.5 - "Mejoras de Productividad"** 🔮 [FUTURO]
**Objetivo:** Incrementar retención

**Features:**
- Edición de comprobantes mal parseados
- Búsqueda/filtros avanzados
- Notificaciones de recordatorio
- Modo silent (auto-detección en background)
- Encriptación de backups con contraseña
- Email destino pre-configurado para backups
- Restauración desde archivo ZIP
- Historial de backups realizados

**Éxito:** 70% retención mensual

---

### **v2.0 - "Premium Features"** 🔮 [FUTURO]
**Objetivo:** Monetización

**Features gratuitas (freemium):**
- Todo de v1.5
- Export CSV ilimitado
- 500 comprobantes/mes

**Features premium (S/ 19.90/mes):**
- Firebase sync (multi-dispositivo)
- Export a Excel
- Gráficos y analytics
- Comprobantes ilimitados
- Backup en cloud
- Soporte prioritario

**Éxito:** 10% conversión a premium

---

## 📊 Métricas de Éxito (MVP)

### **Funcionales**
- ✅ Precisión OCR: >85% en comprobantes Yape/Plin
- ✅ Tiempo de procesamiento: <5 segundos por imagen
- ✅ Tasa de auto-detección correcta: >90%

### **UX**
- ✅ Tiempo de foto a CSV: <30 segundos (incluye 10 imágenes)
- ✅ Pasos para exportar CSV: 3 clicks
- ✅ App funciona sin internet: 100%

### **Negocio**
- 🎯 100 PyMEs activas en primer mes
- 🎯 50 comprobantes procesados/usuario/mes (promedio)
- 🎯 4.0+ rating en Play Store
- 🎯 80% retención semanal

---

## 🎯 Posicionamiento de Marca

### **Slogan**
> "Chiquita pero poderosa"

### **Propuesta de valor en 10 palabras**
> "OCR automático de Yape/Plin para PyMEs peruanas"

### **Diferenciadores clave**
1. **Especialización:** Solo Perú, solo billeteras digitales
2. **Automatización:** Cero intervención manual
3. **Simplicidad:** Una función, perfecta ejecución
4. **Local-first:** Funciona sin internet

---

## 📝 Notas de Decisiones de Diseño

### **¿Por qué SQLite y no Firebase?**
- MVP no necesita sync multi-dispositivo
- Reduce complejidad (sin auth, sin backend)
- Funciona offline 100%
- Más rápido para queries locales
- Sin costos de infraestructura

### **¿Por qué no permitir categorías custom?**
- Va contra el principio de automatización
- El tipo de comprobante ES la categoría natural
- Evita decisiones manuales del usuario
- Mantiene la simplicidad del MVP

### **¿Por qué solo CSV y no Excel?**
- CSV es universal (abre en Excel, Google Sheets, etc.)
- No requiere librerías pesadas
- Suficiente para contadores
- Excel será feature premium en v2.0

### **¿Por qué dark mode por defecto?**
- Reducción de fatiga visual
- Estética moderna
- Menos consumo de batería (OLED)
- Consistente con apps financieras

---

## 🔄 Workflow de Usuario (Happy Path)

```
1. Usuario abre RESILEX
   ↓
2. Toca botón "+" (FAB)
   ↓
3. Selecciona "Galería" o "Cámara"
   ↓
4. Elige 5 screenshots de Yape
   ↓
5. App procesa automáticamente (OCR + Parser)
   [Progress: 1/5... 2/5... 5/5]
   ↓
6. Mensaje: "5 comprobantes guardados ✓"
   ↓
7. Vuelve a Home → Lista actualizada con nuevos tickets
   ↓
8. Usuario toca "Exportar"
   ↓
9. Selecciona "Por mes" → "Agosto 2025"
   ↓
10. Toca "Exportar CSV"
    ↓
11. Mensaje: "CSV exportado: 15 comprobantes"
    ↓
12. Toca "Compartir" → Envía por WhatsApp a contador
```

**Tiempo total:** ~45 segundos  
**Clicks totales:** 8  
**Edición manual:** 0

---

## 📚 Glosario

- **OCR:** Optical Character Recognition (reconocimiento óptico de caracteres)
- **Parser:** Componente que interpreta texto estructurado
- **Strategy Pattern:** Patrón de diseño para intercambiar algoritmos
- **PyME:** Pequeña y Mediana Empresa
- **Yape:** Billetera digital del BCP (Banco de Crédito del Perú)
- **Plin:** Billetera digital multi-banco en Perú
- **SUNAT:** Superintendencia Nacional de Aduanas y de Administración Tributaria
- **SQLite:** Base de datos embebida sin servidor
- **CSV:** Comma-Separated Values (formato de archivo de texto)

---

## 📄 Changelog del Documento

### v2.0 - 2025-12-05 ✅
- **MVP COMPLETADO** - Todas las funcionalidades implementadas
- Agregado sistema de backup ZIP con metadata
- Agregado patrón ZYNC para restauración instantánea
- Actualizado esquema de BD con `receipt_id` y detección de duplicados
- Actualizado stack tecnológico (archive, shared_preferences)
- Actualizada estructura de archivos con todas las pantallas
- Agregadas mejoras de UI/UX (colores actualizados, FAB centrado)
- Agregada selección de mes/año para export y backup
- Documentación de optimizaciones de rendimiento
- Referencias a documentación adicional (patron_zync.md, backup_system.md)

### v1.0 - 2025-12-02
- Definición inicial del concepto MVP
- Documentación de decisiones de arquitectura
- Comparativa con Budgence
- Funcionalidades incluidas/excluidas
- Roadmap hasta v2.0

---

**Mantenido por:** Equipo RESILEX  
**Última actualización:** 5 de diciembre de 2025  
**Estado del proyecto:** ✅ MVP Completado en rama `feature/mvp-ocr-flow`  
**Próximo paso:** Merge a `main` y despliegue para testing con usuarios
