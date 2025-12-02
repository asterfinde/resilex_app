# RESILEX - Concepto del MVP y Funcionalidades

**Fecha de definición:** 2 de diciembre de 2025  
**Versión del documento:** 1.0  
**Estado:** Feature SQLite en desarrollo

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
- ✅ Índices optimizados para queries rápidas
- ✅ CRUD completo:
  - `insertReceipt()`: Guardar nuevo comprobante
  - `getAllReceipts()`: Listar todos (orden descendente)
  - `getReceiptsByMonth()`: Filtrar por mes
  - `getReceiptsByDateRange()`: Filtrar por rango
  - `updateReceipt()`: Editar comprobante
  - `deleteReceipt()`: Eliminar comprobante

#### 3. **HomeScreen - Lista de Comprobantes**
- ✅ Carga automática desde SQLite en `initState()`
- ✅ Lista agrupada por meses (ej: "Diciembre 2025", "Agosto 2025")
- ✅ Ordenamiento descendente (más recientes primero)
- ✅ Diseño BUDgence-style:
  - Círculos de color por tipo
  - Merchant name
  - Amount con formato S/ 1,234.56
  - Fecha
- ✅ Pull-to-refresh para recargar desde DB
- ✅ Loading indicator durante carga inicial
- ✅ Empty state: "Sin comprobantes registrados"
- ✅ FloatingActionButton (+) para agregar comprobante

#### 4. **ImagePickerScreen - Captura/Selección**
- ✅ Selección desde galería (múltiples imágenes)
- ✅ Captura con cámara
- ✅ Preview de imágenes seleccionadas
- ✅ Procesamiento automático con OCR
- ✅ **Auto-guardado en SQLite** después de parseo
- ✅ Progreso de procesamiento (X/Y imágenes)
- ✅ Mensaje de confirmación: "X comprobantes guardados"
- ✅ Retorna a HomeScreen con refresh automático

#### 5. **ExportScreen - Generación de CSV**
- ✅ Opciones de filtro:
  - **Exportar todo:** Todos los comprobantes
  - **Exportar por mes:** Dropdown con meses disponibles
  - **Exportar por rango:** Selector de fechas (pendiente UI)
- ✅ Preview del total a exportar
- ✅ Generación de CSV con formato:
  ```csv
  Fecha,Cliente,Monto,Tipo,Operación,Descripción
  13/08/2025,Clara Nayeli Sac,21.90,yape,09654722,Gasto registrado desde Yape
  ```
- ✅ Guardado en `Downloads/resilex_export_YYYY-MM-DD.csv`
- ✅ Botón "Compartir" para enviar CSV (WhatsApp, email, etc.)
- ✅ Mensaje de éxito con cantidad de comprobantes exportados

#### 6. **UI/UX**
- ✅ Dark mode (#0A0A0A background, #1A1A1A cards)
- ✅ Color scheme: Cyan #22d3ee (accent)
- ✅ Colores por tipo de comprobante:
  - Yape: Morado (fijo)
  - Plin: Cyan #22d3ee (fijo)
  - Boleta: Blanco (fijo)
- ✅ Tipografía: FontWeight.w500 (no bold excesivo)
- ✅ Loading states y error handling
- ✅ SnackBars informativos

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
└── share_plus: ^10.0.3

Utils:
└── intl: ^0.19.0 (formateo de fechas/números)
```

### **Patrón de Arquitectura**

```
lib/
├── main.dart                 # Entry point
├── screens/
│   ├── home_screen.dart      # Lista de comprobantes (desde SQLite)
│   ├── image_picker_screen.dart  # Captura/selección
│   └── export_screen.dart    # Filtros y exportación CSV
├── services/
│   ├── database_service.dart # CRUD SQLite
│   └── csv_exporter_service.dart  # Generación CSV
└── widgets/
    └── ticket_list_item.dart # Componente de lista

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

-- Índices
CREATE INDEX idx_date ON receipts(date DESC);
CREATE INDEX idx_type ON receipts(type);
CREATE INDEX idx_created_at ON receipts(created_at DESC);
```

---

## 🗺️ Roadmap

### **MVP v1.0 - "El Digitalizador"** ✅ [EN DESARROLLO]
**Objetivo:** Probar concepto con PyMEs

**Features:**
- OCR Yape/Plin/Boletas
- Storage SQLite local
- Export CSV básico
- UI simple y funcional

**Éxito:** 100 PyMEs usando la app diariamente

---

### **v1.5 - "Mejoras de Productividad"** 🔮 [FUTURO]
**Objetivo:** Incrementar retención

**Features:**
- Edición de comprobantes mal parseados
- Búsqueda/filtros avanzados
- Notificaciones de recordatorio
- Modo silent (auto-detección en background)
- Backup local (export/import DB)

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

### v1.0 - 2025-12-02
- Definición inicial del concepto MVP
- Documentación de decisiones de arquitectura
- Comparativa con Budgence
- Funcionalidades incluidas/excluidas
- Roadmap hasta v2.0

---

**Mantenido por:** Equipo RESILEX  
**Última actualización:** 2 de diciembre de 2025  
**Estado del proyecto:** Feature SQLite en rama `feature/sqlite-storage`
