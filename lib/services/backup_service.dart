import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt_record.dart';
import 'csv_exporter_service.dart';

/// Servicio para crear backups en formato ZIP
class BackupService {
  final CsvExporterService _csvExporter = CsvExporterService();

  /// Crea un backup ZIP de los comprobantes del mes seleccionado
  /// Retorna el path del archivo ZIP creado
  Future<Map<String, dynamic>> createBackup({
    required List<ReceiptRecord> receipts,
    String? monthFilter,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final monthName = monthFilter ?? 'todos';
      final fileName = 'resilex_backup_${monthName}_$timestamp.zip';

      // 1. Generar CSV en memoria
      final csvData = _csvExporter.generateCsvContent(receipts);

      // 2. Crear metadata.json
      final metadata = _generateMetadata(receipts, monthFilter);

      // 3. Crear archivo ZIP
      final archive = Archive();

      // Agregar CSV al ZIP
      final csvBytes = csvData.codeUnits;
      archive.addFile(
        ArchiveFile('comprobantes.csv', csvBytes.length, csvBytes),
      );

      // Agregar metadata al ZIP
      final metadataBytes = metadata.codeUnits;
      archive.addFile(
        ArchiveFile('metadata.json', metadataBytes.length, metadataBytes),
      );

      // 4. Codificar ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('Error al crear el archivo ZIP');
      }

      // 5. Guardar ZIP en directorio temporal
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(zipBytes);

      // 6. Calcular tamaño del archivo
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      print('✅ [BackupService] ZIP creado: $filePath ($fileSizeMB MB)');

      return {
        'success': true,
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileSizeMB': fileSizeMB,
        'receiptsCount': receipts.length,
        'monthFilter': monthFilter,
      };
    } catch (e) {
      print('❌ [BackupService] Error creando backup: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Genera metadata del backup en formato JSON
  String _generateMetadata(List<ReceiptRecord> receipts, String? monthFilter) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Calcular totales por tipo
    double totalYape = 0;
    double totalPlin = 0;
    double totalBoleta = 0;
    int countYape = 0;
    int countPlin = 0;
    int countBoleta = 0;

    for (final receipt in receipts) {
      switch (receipt.type) {
        case 'yape':
          totalYape += receipt.amount;
          countYape++;
          break;
        case 'plin':
          totalPlin += receipt.amount;
          countPlin++;
          break;
        case 'boleta':
          totalBoleta += receipt.amount;
          countBoleta++;
          break;
      }
    }

    final total = totalYape + totalPlin + totalBoleta;

    // Generar JSON manualmente (sin dependencia de dart:convert)
    return '''
{
  "app": "RESILEX",
  "version": "1.0.0",
  "backup_date": "${dateFormat.format(now)}",
  "month_filter": ${monthFilter != null ? '"$monthFilter"' : 'null'},
  "receipts_count": ${receipts.length},
  "summary": {
    "total_amount": $total,
    "yape": {
      "count": $countYape,
      "total": $totalYape
    },
    "plin": {
      "count": $countPlin,
      "total": $totalPlin
    },
    "boleta": {
      "count": $countBoleta,
      "total": $totalBoleta
    }
  },
  "note": "Backup generado automáticamente por RESILEX. Este archivo contiene los comprobantes digitalizados en formato CSV."
}
''';
  }

  /// Elimina archivos de backup antiguos del directorio temporal
  Future<void> cleanOldBackups() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('resilex_backup_')) {
          await file.delete();
          print('🧹 [BackupService] Backup antiguo eliminado: ${file.path}');
        }
      }
    } catch (e) {
      print('⚠️ [BackupService] Error limpiando backups antiguos: $e');
    }
  }
}
