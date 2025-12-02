# 📋 Product Backlog - Yape CSV Exporter

**Proyecto:** Mini-app de extracción y exportación de datos de tickets  
**Plataforma inicial:** Android (Flutter)  
**Fecha de creación:** 01 de Diciembre 2025  
**Estado:** MVP en desarrollo

---

## 🎯 Visión del Producto

Aplicación móvil independiente que permite a los usuarios procesar automáticamente imágenes de tickets de pago (Yape, Plin, boletas, etc.) desde su galería, extraer datos estructurados mediante OCR e IA, y exportarlos en formato CSV/Excel sin intervención manual.

---

## 📱 User Stories - MVP (Prioridad Alta)

### Epic 1: Captura y Selección de Imágenes

#### US-001: Seleccionar imágenes desde la galería
**Como** usuario de la app  
**Quiero** seleccionar múltiples imágenes de tickets desde mi galería  
**Para** procesarlas todas de una vez sin tener que ir una por una

**Criterios de aceptación:**
- ✅ Puedo seleccionar hasta 20 imágenes simultáneamente
- ✅ Puedo ver un contador de "X imágenes seleccionadas"
- ✅ Puedo deseleccionar imágenes antes de procesar
- ✅ Funciona con formatos JPG, PNG, WEBP
- ✅ Muestra preview thumbnail de cada imagen seleccionada

**Estimación:** 3 puntos  
**Prioridad:** P0 (Crítico)

---

#### US-002: Tomar foto directa con la cámara
**Como** usuario de la app  
**Quiero** capturar un ticket directamente con la cámara  
**Para** no tener que guardarlo primero en la galería

**Criterios de aceptación:**
- ✅ Botón "Tomar foto" abre la cámara nativa
- ✅ Después de tomar la foto, se agrega automáticamente a la lista
- ✅ Puedo tomar múltiples fotos seguidas

**Estimación:** 2 puntos  
**Prioridad:** P1 (Alta)

---

### Epic 2: Procesamiento OCR e IA

#### US-003: Procesar imágenes automáticamente con OCR
**Como** usuario de la app  
**Quiero** que la app extraiga automáticamente el texto de mis tickets  
**Para** no tener que escribir nada manualmente

**Criterios de aceptación:**
- ✅ Procesa automáticamente al seleccionar "Procesar"
- ✅ Muestra barra de progreso "Procesando X/Y..."
- ✅ Usa Google ML Kit para OCR local
- ✅ Funciona sin conexión a internet (excepto fallback IA)

**Estimación:** 5 puntos  
**Prioridad:** P0 (Crítico)

---

#### US-004: Identificar automáticamente el tipo de ticket
**Como** usuario de la app  
**Quiero** que la app reconozca automáticamente si es Yape, Plin, boleta, etc.  
**Para** obtener datos precisos sin configurar nada

**Criterios de aceptación:**
- ✅ Detecta automáticamente: Yape, Plin, Boletas Electrónicas
- ✅ Usa patrón Strategy para seleccionar el parser correcto
- ✅ Si no reconoce el tipo, usa IA (Claude) como fallback
- ✅ Muestra el tipo detectado (ej: "Ticket Yape detectado")

**Estimación:** 3 points (ya está implementado en Budgence)  
**Prioridad:** P0 (Crítico)

---

#### US-005: Extraer datos clave de cada ticket
**Como** usuario de la app  
**Quiero** que la app extraiga automáticamente comercio, monto, fecha, número de operación  
**Para** tener todos los datos estructurados sin escribir nada

**Criterios de aceptación:**
- ✅ Extrae: merchant (comercio), amount (monto), date (fecha/hora), operationNumber
- ✅ Formato de monto: número decimal (45.50)
- ✅ Formato de fecha: DD/MM/YYYY HH:mm
- ✅ Si falta algún dato, muestra "N/A" o vacío

**Estimación:** 5 puntos (ya implementado, solo adaptar)  
**Prioridad:** P0 (Crítico)

---

### Epic 3: Visualización de Resultados

#### US-006: Ver lista de tickets procesados
**Como** usuario de la app  
**Quiero** ver todos los tickets procesados en una lista clara  
**Para** revisar rápidamente qué se extrajo

**Criterios de aceptación:**
- ✅ Muestra tarjeta por cada ticket con: comercio, monto, fecha, #operación
- ✅ Indica si el procesamiento fue exitoso o falló
- ✅ Muestra ícono según tipo (💳 Yape, 📱 Plin, 🧾 Boleta)
- ✅ Muestra total acumulado en la parte superior

**Estimación:** 3 puntos  
**Prioridad:** P0 (Crítico)

---

#### US-007: Ver imagen original del ticket
**Como** usuario de la app  
**Quiero** poder ver la imagen original de cada ticket  
**Para** verificar visualmente si los datos son correctos

**Criterios de aceptación:**
- ✅ Al tocar una tarjeta, se muestra la imagen en tamaño completo
- ✅ Puedo hacer zoom en la imagen
- ✅ Puedo cerrar la vista con botón "X" o gesture

**Estimación:** 2 puntos  
**Prioridad:** P2 (Media)

---

### Epic 4: Exportación de Datos

#### US-008: Exportar datos a CSV
**Como** usuario de la app  
**Quiero** exportar todos los datos procesados a un archivo CSV  
**Para** abrirlo en Excel o Google Sheets

**Criterios de aceptación:**
- ✅ Genera archivo CSV con columnas: Fecha, Comercio, Monto, NumOperacion, Tipo
- ✅ Nombre del archivo: `tickets_export_DDMMYYYY_HHmm.csv`
- ✅ Formato compatible con Excel (comas, encoding UTF-8)
- ✅ Guarda en carpeta Downloads del dispositivo

**Estimación:** 3 puntos  
**Prioridad:** P0 (Crítico)

---

#### US-009: Compartir archivo CSV
**Como** usuario de la app  
**Quiero** compartir el archivo CSV generado  
**Para** enviarlo por WhatsApp, email, Drive, etc.

**Criterios de aceptación:**
- ✅ Botón "Compartir" abre el share sheet nativo de Android
- ✅ Puedo compartir a cualquier app (WhatsApp, Gmail, Drive, etc.)
- ✅ El archivo se comparte con el nombre correcto

**Estimación:** 2 puntos  
**Prioridad:** P1 (Alta)

---

#### US-010: Preparación para exportación a Excel
**Como** usuario de la app  
**Quiero** que el sistema esté preparado para exportar a Excel nativo (.xlsx)  
**Para** facilitar la migración futura del formato CSV

**Criterios de aceptación:**
- ✅ Arquitectura del CsvExporter permite agregar XlsxExporter
- ✅ Interfaz común `FileExporter` para múltiples formatos
- ✅ Documentación de cómo implementar Excel en el futuro

**Estimación:** 1 punto (solo preparación arquitectónica)  
**Prioridad:** P3 (Baja - futuro)

---

### Epic 5: Experiencia de Usuario

#### US-011: Ver mensajes de error claros
**Como** usuario de la app  
**Quiero** ver mensajes de error claros cuando algo falla  
**Para** entender qué pasó y qué hacer

**Criterios de aceptación:**
- ✅ Si OCR falla: "No se pudo leer la imagen. Intenta con mejor iluminación"
- ✅ Si no detecta monto: "No se encontró un monto en este ticket"
- ✅ Si no hay internet (para IA): "Procesamiento parcial. Verifica tu conexión"
- ✅ Opción de "Reintentar" en cada error

**Estimación:** 2 puntos  
**Prioridad:** P1 (Alta)

---

#### US-012: Ver splash screen y onboarding
**Como** nuevo usuario de la app  
**Quiero** ver instrucciones básicas la primera vez  
**Para** entender cómo usar la app

**Criterios de aceptación:**
- ✅ Splash screen con logo al iniciar
- ✅ Onboarding de 3 pasos (solo primera vez):
  1. "Selecciona tus tickets"
  2. "Procesamos automáticamente"
  3. "Exporta a CSV"
- ✅ Botón "Omitir" para usuarios avanzados

**Estimación:** 3 puntos  
**Prioridad:** P2 (Media)

---

## 🚀 User Stories - Post-MVP (Backlog Futuro)

### Epic 6: Funcionalidades Avanzadas

#### US-013: Guardar historial de exportaciones
**Como** usuario de la app  
**Quiero** ver un historial de mis exportaciones anteriores  
**Para** volver a exportar o consultar datos pasados

**Estimación:** 5 puntos  
**Prioridad:** P3 (Baja - futuro)

---

#### US-014: Filtrar tickets por fecha o tipo
**Como** usuario de la app  
**Quiero** filtrar tickets por rango de fechas o tipo (Yape/Plin/Boleta)  
**Para** exportar solo lo que necesito

**Estimación:** 3 puntos  
**Prioridad:** P3 (Baja - futuro)

---

#### US-015: Editar datos antes de exportar
**Como** usuario de la app  
**Quiero** poder editar manualmente un dato extraído incorrectamente  
**Para** corregir errores del OCR antes de exportar

**Estimación:** 5 puntos  
**Prioridad:** P3 (Baja - según requerimiento actual "sin intervención")

---

#### US-016: Exportar a Google Sheets automáticamente
**Como** usuario de la app  
**Quiero** exportar directamente a mi Google Sheets  
**Para** no tener que importar el CSV manualmente

**Estimación:** 8 puntos  
**Prioridad:** P3 (Baja - futuro)

---

## 📊 Métricas de Éxito del MVP

- ✅ Procesa al menos 15 imágenes en menos de 2 minutos
- ✅ Precisión de extracción > 90% en tickets de Yape
- ✅ Precisión de extracción > 80% en tickets genéricos
- ✅ Genera CSV válido que se abre correctamente en Excel
- ✅ Tamaño de APK < 50 MB
- ✅ Funciona sin internet (excepto fallback IA)

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

## 🎯 Definición de "Done"

Una User Story se considera completa cuando:
- ✅ Código implementado y funcional
- ✅ Sin errores de compilación
- ✅ Probado en dispositivo Android físico
- ✅ UI responsive y sin bugs visuales
- ✅ Manejo de errores implementado
- ✅ Code review (si aplica)

---

## 📝 Notas y Decisiones

### Decisiones de Diseño
- **No edición manual:** Datos extraídos son finales (llave en mano)
- **Procesamiento universal:** Cualquier tipo de ticket
- **Arquitectura modular:** Reutiliza código de Budgence
- **Exportación extensible:** Preparado para múltiples formatos

### Dependencias de Budgence
El siguiente código se reutiliza de `budgence-app`:
- `OcrService` - OCR con ML Kit
- `ParserService` - Orquestador de estrategias
- `YapeParsingStrategy` - Parser de Yape
- `PlinStrategy` - Parser de Plin
- `BoletaElectronicaStrategy` - Parser de boletas
- `ClaudeParsingStrategy` - Fallback con IA
- `ReceiptData` - Modelo de datos

---

**Última actualización:** 01/12/2025  
**Próxima revisión:** Después del Sprint 1
