# Sistema de Backup RESILEX

## 📋 Descripción General

Sistema de respaldo de datos que permite al usuario exportar sus comprobantes digitalizados en formato ZIP para compartir vía email, Drive, WhatsApp u otras aplicaciones.

---

## 🎯 Características

### ✅ Implementado (MVP - Fase 1)

1. **Backup Manual por Mes**
   - Usuario selecciona el mes específico a respaldar
   - Opción de respaldar todos los comprobantes

2. **Formato ZIP**
   - Archivo comprimido con CSV + metadata
   - Sin encriptación (para simplicidad del MVP)
   - Tamaño optimizado

3. **Compartir con share_plus**
   - Share sheet nativo de Android/iOS
   - Usuario elige destino: Email, Drive, WhatsApp, etc.
   - Pre-llena asunto y descripción

4. **Contenido del Backup**
   ```
   resilex_backup_diciembre_2025_20251205_160000.zip
   ├── comprobantes.csv          (Datos tabulares)
   └── metadata.json             (Info del backup)
   ```

---

## 🔄 Flujo de Usuario

```
Home Screen
    ↓
Tap ícono Backup (☁️)
    ↓
Seleccionar período:
  - Todos los comprobantes
  - Mes específico (ej: Diciembre 2025)
    ↓
Generar ZIP (2-3 segundos)
    ↓
Share Sheet nativo
    ↓
Usuario elige destino:
  - Gmail / Outlook
  - Google Drive / Dropbox
  - WhatsApp / Telegram
  - Guardar en dispositivo
```

---

## 🏗️ Arquitectura

### Componentes Principales

#### 1. **BackupService** (`lib/services/backup_service.dart`)

Servicio encargado de crear el archivo ZIP.

**Métodos principales:**
```dart
Future<Map<String, dynamic>> createBackup({
  required List<ReceiptRecord> receipts,
  String? monthFilter,
})
```

**Proceso:**
1. Genera CSV usando `CsvExporterService`
2. Crea metadata.json con estadísticas
3. Comprime ambos archivos en ZIP
4. Guarda en directorio temporal
5. Retorna path del archivo

#### 2. **BackupSelectionScreen** (`lib/screens/backup_selection_screen.dart`)

Pantalla de selección de período a respaldar.

**Características:**
- Lista de meses disponibles
- Botón destacado para "Respaldar todos"
- Muestra cantidad de comprobantes y total por mes
- Indicador de carga mientras crea el ZIP

#### 3. **Integración en HomeScreen**

Botón de backup en AppBar:
```dart
IconButton(
  icon: const Icon(Icons.backup_outlined),
  onPressed: _navigateToBackup,
  tooltip: 'Crear Backup',
)
```

---

## 📦 Estructura del ZIP

### comprobantes.csv
Formato estándar CSV con los siguientes campos:
- Fecha
- Hora
- Comercio
- Monto
- Número de Operación
- Descripción
- Tipo (yape/plin/boleta)

### metadata.json
```json
{
  "app": "RESILEX",
  "version": "1.0.0",
  "backup_date": "2025-12-05 16:00:00",
  "month_filter": "Diciembre 2025",
  "receipts_count": 15,
  "summary": {
    "total_amount": 450.50,
    "yape": {
      "count": 8,
      "total": 250.00
    },
    "plin": {
      "count": 5,
      "total": 150.50
    },
    "boleta": {
      "count": 2,
      "total": 50.00
    }
  },
  "note": "Backup generado automáticamente por RESILEX..."
}
```

---

## 🔐 Seguridad

### Fase 1 (MVP - Actual)
- ❌ Sin encriptación
- ✅ Datos no pasan por servidor externo
- ✅ Usuario controla dónde se guarda
- ⚠️ Archivos temporales se limpian automáticamente

**Justificación:**
- Datos no son ultra sensibles (comprobantes comerciales)
- Simplicidad para MVP
- Usuario puede elegir destino seguro (Drive personal)

### Fase 2 (Futuro)
- ✅ Encriptación AES-256 con contraseña
- ✅ Configuración de email destino
- ✅ Contraseña maestra para proteger backups

---

## 📊 Rendimiento

### Tamaños Estimados

| Comprobantes | CSV | ZIP | Tiempo |
|--------------|-----|-----|--------|
| 10           | ~2 KB | ~1 KB | <1s |
| 50           | ~10 KB | ~4 KB | 1-2s |
| 100          | ~20 KB | ~8 KB | 2-3s |
| 500          | ~100 KB | ~40 KB | 5-8s |

**Límites de Email:**
- Gmail: 25 MB
- Outlook: 20 MB
- **Conclusión:** Soporta miles de comprobantes sin problema

---

## 🚀 Mejoras Futuras (Roadmap)

### Fase 2: Seguridad
```
✅ Encriptación opcional con contraseña
✅ Pantalla de configuración de backup
✅ Email destino pre-configurado
```

### Fase 3: Automatización
```
✅ Backup automático programado (semanal/mensual)
✅ Notificaciones de backup completado
✅ Historial de backups realizados
```

### Fase 4: Restauración
```
✅ Importar desde ZIP
✅ Detectar duplicados al restaurar
✅ Merge inteligente de datos
```

### Fase 5: Avanzado
```
✅ Incluir imágenes de comprobantes en ZIP
✅ Backup incremental (solo cambios)
✅ Sincronización con Google Drive API
```

---

## 🧪 Testing

### Casos de Prueba

1. **Backup de mes vacío**
   - ✅ Debe mostrar mensaje apropiado

2. **Backup de mes con 1 comprobante**
   - ✅ Debe generar ZIP válido

3. **Backup de todos los comprobantes**
   - ✅ Debe incluir todos los meses

4. **Compartir vía Email**
   - ✅ Debe abrir cliente de email
   - ✅ Debe adjuntar ZIP correctamente

5. **Compartir vía Drive**
   - ✅ Debe abrir selector de Drive
   - ✅ Debe subir archivo correctamente

6. **Limpieza de archivos temporales**
   - ✅ Debe eliminar ZIPs antiguos
   - ✅ No debe llenar el almacenamiento

---

## 📝 Notas de Implementación

### Dependencias Utilizadas
```yaml
archive: ^3.4.10      # Crear archivos ZIP
share_plus: ^10.0.3   # Compartir archivos
path_provider: ^2.1.5 # Directorio temporal
csv: ^6.0.0           # Generar CSV
```

### Directorio de Trabajo
```dart
final directory = await getTemporaryDirectory();
// Android: /data/user/0/com.datainfers.resilex/cache/
// iOS: /var/mobile/Containers/Data/Application/.../tmp/
```

**Ventaja:** Se limpia automáticamente por el sistema operativo

---

## 🐛 Troubleshooting

### Problema: "Error al crear backup"
**Causa:** Permisos de almacenamiento  
**Solución:** Verificar permisos en AndroidManifest.xml

### Problema: "Archivo muy grande para email"
**Causa:** Demasiados comprobantes  
**Solución:** Respaldar por mes en lugar de todos

### Problema: "No se puede compartir"
**Causa:** No hay apps compatibles instaladas  
**Solución:** Instalar Gmail, Drive u otra app

---

## 📚 Referencias

- [archive package](https://pub.dev/packages/archive)
- [share_plus package](https://pub.dev/packages/share_plus)
- [ZIP File Format Specification](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)

---

**Última actualización:** 5 de diciembre de 2025  
**Versión:** 1.0.0 (MVP - Fase 1)
