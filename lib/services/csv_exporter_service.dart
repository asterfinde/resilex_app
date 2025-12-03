import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/receipt_record.dart';

/// Servicio para exportar datos de recibos a formato CSV
class CsvExporterService {
  /// Genera el contenido CSV desde una lista de recibos
  String generateCsvContent(List<ReceiptRecord> receipts) {
    if (receipts.isEmpty) {
      return '';
    }

    // Definir headers
    final List<List<dynamic>> rows = [
      [
        'Fecha',
        'Hora',
        'Comercio',
        'Monto',
        'Número de Operación',
        'Descripción',
        'Tipo',
      ],
    ];

    // Agregar datos de cada recibo
    for (final receipt in receipts) {
      rows.add([
        receipt.date,
        receipt.time ?? 'N/A',
        receipt.merchant,
        receipt.amount.toStringAsFixed(2),
        receipt.operationNumber ?? 'N/A',
        receipt.description ?? '',
        receipt.type,
      ]);
    }

    // Convertir a CSV
    return const ListToCsvConverter().convert(rows);
  }

  /// Genera el nombre del archivo con timestamp
  String generateFileName() {
    final now = DateTime.now();
    final formattedDate = DateFormat('ddMMyyyy_HHmm').format(now);
    return 'resilex_export_$formattedDate.csv';
  }

  /// Guarda el CSV en el almacenamiento local y retorna la ruta
  Future<String> saveCsvToFile(String csvContent, String fileName) async {
    try {
      // Obtener directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Crear y escribir archivo
      final file = File(filePath);
      await file.writeAsString(csvContent);

      return filePath;
    } catch (e) {
      throw Exception('Error al guardar archivo CSV: $e');
    }
  }

  /// Comparte el archivo CSV usando el share sheet nativo
  Future<void> shareCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo CSV no encontrado');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Exportación de Comprobantes Resilex',
        text: 'Aquí está tu archivo CSV con los comprobantes procesados',
      );
    } catch (e) {
      throw Exception('Error al compartir archivo CSV: $e');
    }
  }

  /// Proceso completo: generar, guardar y compartir
  Future<Map<String, dynamic>> exportAndShare(
    List<ReceiptRecord> receipts,
  ) async {
    try {
      // Generar contenido CSV
      final csvContent = generateCsvContent(receipts);

      if (csvContent.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Generar nombre de archivo
      final fileName = generateFileName();

      // Guardar archivo
      final filePath = await saveCsvToFile(csvContent, fileName);

      // Calcular estadísticas
      final totalAmount = receipts.fold<double>(
        0,
        (sum, receipt) => sum + receipt.amount,
      );

      return {
        'success': true,
        'filePath': filePath,
        'fileName': fileName,
        'recordCount': receipts.length,
        'totalAmount': totalAmount,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Calcula estadísticas de los recibos
  Map<String, dynamic> getStatistics(List<ReceiptRecord> receipts) {
    if (receipts.isEmpty) {
      return {'total': 0, 'totalAmount': 0.0, 'byType': <String, int>{}};
    }

    final totalAmount = receipts.fold<double>(
      0,
      (sum, receipt) => sum + receipt.amount,
    );

    final Map<String, int> byType = {};
    for (final receipt in receipts) {
      byType[receipt.type] = (byType[receipt.type] ?? 0) + 1;
    }

    return {
      'total': receipts.length,
      'totalAmount': totalAmount,
      'byType': byType,
      'avgAmount': totalAmount / receipts.length,
    };
  }
}
