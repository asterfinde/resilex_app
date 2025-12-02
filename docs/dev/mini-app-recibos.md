# Mini-App de Lectura de Recibos - Documentación Técnica

## 📱 Tu Visión: Mini-App Android MVP

Lo que necesitas es una **aplicación móvil completa** (no solo un paquete/librería), con esta funcionalidad:

```
Usuario abre la app Android
    ↓
Selecciona una o varias imágenes de Yape/tickets desde la galería
    ↓
La app procesa automáticamente con OCR
    ↓
Extrae: merchant, amount, date, operationNumber
    ↓
Muestra los resultados en pantalla
    ↓
Usuario presiona "Exportar CSV"
    ↓
Se genera un archivo CSV con todos los registros
    ↓
Usuario puede compartir/descargar el CSV
```

---

## 🎯 Opciones de Arquitectura

### **Opción 1: App Independiente (Recomendada para MVP)**
Una app Flutter completamente nueva y separada de Budgence:

```
📱 yape_csv_exporter/          ← Nueva app independiente
├── lib/
│   ├── main.dart              ← Entry point
│   ├── screens/
│   │   ├── home_screen.dart         ← Seleccionar imágenes
│   │   ├── results_screen.dart      ← Ver datos extraídos
│   │   └── export_screen.dart       ← Exportar CSV
│   ├── services/
│   │   ├── ocr_service.dart         ← Copiado de budgence
│   │   ├── parser_service.dart      ← Copiado de budgence
│   │   └── csv_service.dart         ← NUEVO: genera CSV
│   ├── strategies/                   ← Todas las estrategias
│   └── models/
│       └── receipt_data.dart        ← Modelo de datos
├── android/                   ← Configuración Android
└── pubspec.yaml
```

**Ventajas:**
- ✅ MVP rápido y enfocado
- ✅ No afecta Budgence
- ✅ Fácil de distribuir (APK independiente)
- ✅ Puede reutilizar código de Budgence

---

### **Opción 2: Feature dentro de Budgence**
Agregar esta funcionalidad como una nueva pantalla en Budgence:

```
budgence-app/
├── lib/
│   ├── features/
│   │   ├── expense_capture/      ← Ya existe
│   │   ├── csv_exporter/         ← NUEVO FEATURE
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── batch_import_screen.dart
│   │   │   │   │   └── csv_export_screen.dart
│   │   │   │   └── widgets/
│   │   │   └── services/
│   │   │       └── csv_exporter_service.dart
```

**Ventajas:**
- ✅ Reutiliza todo el código existente
- ✅ Una sola app para el usuario
- ⚠️ Aumenta complejidad de Budgence

---

## 🎨 UI/UX Propuesta para la Mini-App

### **Pantalla 1: Home (Selección de Imágenes)**
```dart
┌─────────────────────────────┐
│  Yape CSV Exporter          │
├─────────────────────────────┤
│                             │
│   📸  Seleccionar Tickets   │
│                             │
│   Imágenes seleccionadas: 0 │
│                             │
│   [Galería]  [Cámara]       │
│                             │
│   ─────────────────────     │
│                             │
│   📋 Historial:             │
│   • 15 tickets (30/11/2025) │
│   • 8 tickets (29/11/2025)  │
│                             │
└─────────────────────────────┘
```

### **Pantalla 2: Procesamiento y Vista Previa**
```dart
┌─────────────────────────────┐
│  ← Procesando...            │
├─────────────────────────────┤
│                             │
│  ✓ Imagen 1/5 procesada     │
│                             │
│  Datos extraídos:           │
│  ┌───────────────────────┐  │
│  │ 🏪 Juan Perez        │  │
│  │ 💰 S/ 45.50          │  │
│  │ 📅 01/12/2025 14:30  │  │
│  │ #️⃣ 123456789         │  │
│  │ [Editar] [Eliminar]  │  │
│  └───────────────────────┘  │
│                             │
│  [+ Agregar más]            │
│  [📥 Exportar CSV]          │
│                             │
└─────────────────────────────┘
```

### **Pantalla 3: Exportación**
```dart
┌─────────────────────────────┐
│  ← CSV Generado ✓           │
├─────────────────────────────┤
│                             │
│  📄 yape_export_01_12.csv   │
│                             │
│  5 registros exportados     │
│  Total: S/ 234.50           │
│                             │
│  Vista previa:              │
│  ┌───────────────────────┐  │
│  │Fecha,Comercio,Monto...│  │
│  │01/12/25,Juan,45.50,...│  │
│  │01/12/25,Maria,80.00...│  │
│  └───────────────────────┘  │
│                             │
│  [📤 Compartir]             │
│  [💾 Guardar en Descargas]  │
│                             │
└─────────────────────────────┘
```

---

## 💡 Recomendación Profesional

Para un **MVP rápido y efectivo**, se sugiere:

### **🎯 Estrategia híbrida:**

1. **Extraer código reutilizable a un paquete Dart local**
   ```
   packages/
   └── receipt_parser/       ← Paquete local (no publicado)
       ├── lib/
       │   ├── models/
       │   ├── services/
       │   └── strategies/
       └── pubspec.yaml
   ```

2. **Crear app independiente que usa el paquete**
   ```
   yape_csv_exporter/        ← Nueva app Flutter
   └── pubspec.yaml:
       dependencies:
         receipt_parser:
           path: ../packages/receipt_parser/
   ```

3. **Budgence también puede usar el paquete**
   ```
   budgence-app/
   └── pubspec.yaml:
       dependencies:
         receipt_parser:
           path: ../packages/receipt_parser/
   ```

---

## 📊 Requerimientos Confirmados del Usuario

1. **App independiente:** Sí
2. **Edición manual:** No - todo va llave en mano, sin intervención alguna para garantizar la integridad de la data
3. **Formatos de exportación:** CSV/Excel (abierto a múltiples formatos)
4. **Tipos de tickets:** Universal - Yape, Plin o cualquier otro ticket de venta en general

---

## 📊 Flutter vs Kotlin Nativo en VSCode

### **🎯 Recomendación: FLUTTER** (100% seguro)

| Criterio | Flutter | Kotlin Nativo |
|----------|---------|---------------|
| **Soporte VSCode** | ⭐⭐⭐⭐⭐ Excelente | ⭐⭐ Limitado |
| **Reutilización de código Budgence** | ✅ 100% | ❌ 0% (hay que reescribir) |
| **Tiempo de desarrollo MVP** | 🚀 2-3 días | 🐌 1-2 semanas |
| **OCR + Parsing ya implementado** | ✅ Copiar y pegar | ❌ Reescribir todo |
| **Multiplataforma futuro** | ✅ iOS gratis | ❌ Solo Android |
| **Hot Reload** | ✅ Sí | ⚠️ Limitado en VSCode |
| **Debugging en VSCode** | ✅ Excelente | ⚠️ Requiere Android Studio |
| **Curva de aprendizaje** | Ya lo conoces | Nueva tecnología |

### **💡 Por qué Flutter es la opción correcta:**

1. **Ya tienes TODO el código funcionando** en Budgence (OCR, parsing strategies, modelos)
2. **VSCode tiene soporte de primera** para Flutter (extensión oficial de Google)
3. **Reutilizas 80% del código** de Budgence
4. **MVP en días, no semanas**
5. **Kotlin nativo en VSCode es doloroso** (mejor con Android Studio)

---

## 🏗️ Arquitectura Técnica

### Stack Tecnológico
- **Framework:** Flutter 3.24+
- **Lenguaje:** Dart 3.5+
- **OCR:** Google ML Kit Text Recognition
- **IA Fallback:** Claude API (Firebase Functions)
- **Plataforma:** Android (API 21+)

### Módulos Principales
```
lib/
├── screens/          # UI
├── services/         # Lógica de negocio
│   ├── ocr_service.dart
│   ├── parser_service.dart
│   └── csv_exporter_service.dart
├── strategies/       # Pattern Strategy para parsers
│   ├── yape_strategy.dart
│   ├── plin_strategy.dart
│   ├── boleta_strategy.dart
│   └── claude_strategy.dart
└── models/           # Modelos de datos
    └── receipt_data.dart
```

---

## 🔧 Componentes Identificados en Budgence

### **1. OcrService** (`lib/core/services/ocr_service.dart`)
- Usa Google ML Kit para OCR
- Extrae texto de imágenes
- Independiente del tipo de documento

### **2. ParserService** (`lib/core/services/parser_service.dart`)
- Implementa el **Patrón Strategy**
- Coordina múltiples estrategias de parsing
- Selecciona automáticamente la estrategia correcta

### **3. Estrategias de Parsing** (todas implementan `ParsingStrategy`):
- `YapeParsingStrategy` - Específica para Yape
- `PlinStrategy` - Para Plin
- `BoletaElectronicaStrategy` - Boletas electrónicas
- `ClaudeParsingStrategy` - Fallback con IA (Claude)

### **4. ReceiptData** (`lib/features/expense_capture/data/models/receipt_data_model.dart`)
- Modelo de datos común para todos los tipos de recibos
- Estructura: merchant, amount, date, time, operationNumber, description

---

## 📦 Archivos a Extraer para Módulo Independiente

```
📦 receipt_parser_sdk/
├── lib/
│   ├── models/
│   │   └── receipt_data.dart          ← ReceiptData (modelo universal)
│   ├── services/
│   │   ├── ocr_service.dart           ← OCR
│   │   └── parser_service.dart        ← Orquestador
│   ├── strategies/
│   │   ├── parsing_strategy.dart      ← Interface
│   │   ├── yape_strategy.dart         ← Yape específico
│   │   ├── plin_strategy.dart         ← Plin
│   │   ├── boleta_strategy.dart       ← Boletas
│   │   └── claude_strategy.dart       ← IA fallback
│   └── receipt_parser.dart            ← API pública del SDK
├── pubspec.yaml
└── README.md
```

### **Dependencias externas a considerar:**
- `google_mlkit_text_recognition` (OCR)
- `cloud_functions` (solo para ClaudeStrategy)
- `intl` (formateo de fechas)

---

## 🎯 Ventajas del Diseño Actual (Patrón Strategy)

1. ✅ **Interfaz clara**: `ParsingStrategy` define el contrato
2. ✅ **Bajo acoplamiento**: Cada estrategia es independiente
3. ✅ **Fácil extensión**: Agregar nuevas estrategias sin modificar código existente
4. ✅ **Testeable**: Cada estrategia se puede probar por separado
5. ✅ **Reutilizable**: No depende de Flutter (excepto `debugPrint`)

---

## 💾 Funcionalidad de Exportación CSV - Propuesta

```dart
// Funcionalidad adicional para el SDK
class CsvExporter {
  static String exportBatch(List<ReceiptData> receipts) {
    final csv = StringBuffer();
    
    // Header
    csv.writeln('Fecha,Comercio,Monto,Número de Operación,Descripción');
    
    // Data rows
    for (final receipt in receipts) {
      csv.writeln([
        receipt.date,
        receipt.merchant,
        receipt.amount,
        receipt.operationNumber ?? '',
        receipt.description ?? '',
      ].join(','));
    }
    
    return csv.toString();
  }
}
```

---

## 🚀 Próximos Pasos Sugeridos

1. **Crear estructura del paquete** independiente
2. **Extraer código** sin dependencias de Firebase/Riverpod
3. **Crear CLI tool** para procesamiento batch de imágenes
4. **Agregar exportador CSV/JSON**
5. **Publicar en pub.dev** (opcional)

---

## 📅 Sprint Planning Sugerido

### Sprint 1 (MVP Core - 1 semana)
- US-001: Selección de galería ✅
- US-003: OCR básico ✅
- US-004: Auto-detección tipo ✅
- US-005: Extracción datos ✅

### Sprint 2 (MVP UX - 1 semana)
- US-006: Vista de resultados ✅
- US-008: Exportar CSV ✅
- US-009: Compartir archivo ✅
- US-011: Manejo de errores ✅

### Sprint 3 (Polish - 3 días)
- US-002: Captura con cámara ✅
- US-012: Splash y onboarding ✅
- Testing y bugs ✅
- Preparar APK ✅

---

## 📊 Métricas de Éxito del MVP

- ✅ Procesa al menos 15 imágenes en menos de 2 minutos
- ✅ Precisión de extracción > 90% en tickets de Yape
- ✅ Precisión de extracción > 80% en tickets genéricos
- ✅ Genera CSV válido que se abre correctamente en Excel
- ✅ Tamaño de APK < 50 MB
- ✅ Funciona sin internet (excepto fallback IA)

---

## 🎯 Definición de "Done"

Una User Story se considera completa cuando:
- ✅ Código implementado y funcional
- ✅ Sin errores de compilación
- ✅ Probado en dispositivo Android físico
- ✅ UI responsive y sin bugs visuales
- ✅ Manejo de errores implementado
- ✅ Code review (si aplica)

---

## 📝 Decisiones de Diseño

- **No edición manual:** Datos extraídos son finales (llave en mano)
- **Procesamiento universal:** Cualquier tipo de ticket
- **Arquitectura modular:** Reutiliza código de Budgence
- **Exportación extensible:** Preparado para múltiples formatos

---

**Fecha de creación:** 01 de Diciembre 2025  
**Última actualización:** 01/12/2025  
**Estado:** Documentación inicial completada
