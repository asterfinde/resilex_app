import 'package:receipt_parser/receipt_parser.dart';

/// Modelo de datos para un comprobante guardado en SQLite.
/// Extiende ReceiptData del parser con campos adicionales para persistencia.
class ReceiptRecord {
  final int? id; // ID de SQLite (null si no está guardado aún)
  final String
  receiptId; // ID alfanumérico: <type><operationNumber> ej: y56854, p1228777
  final String merchant; // Comercio/Cliente
  final double amount; // Monto
  final String date; // Fecha en formato "dd/MM/yyyy"
  final String? time; // Hora en formato "HH:mm"
  final String type; // Tipo: "yape", "plin", "boleta", "unknown"
  final String? operationNumber; // Número de operación
  final String? description; // Descripción adicional
  final DateTime? createdAt; // Timestamp de creación
  final DateTime? updatedAt; // Timestamp de actualización

  ReceiptRecord({
    this.id,
    String? receiptId,
    required this.merchant,
    required this.amount,
    required this.date,
    this.time,
    required this.type,
    this.operationNumber,
    this.description,
    this.createdAt,
    this.updatedAt,
  }) : receiptId = receiptId ?? _generateReceiptId(type, operationNumber);

  /// Crea un ReceiptRecord desde ReceiptData del parser
  factory ReceiptRecord.fromReceiptData(ReceiptData data) {
    return ReceiptRecord(
      merchant: data.merchant ?? 'Desconocido',
      amount: data.amount ?? 0.0,
      date: data.date ?? '',
      time: data.time,
      type: _detectType(data.description),
      operationNumber: data.operationNumber,
      description: data.description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Genera el ID alfanumérico del comprobante: <type_prefix><operation_number>
  /// Ejemplos: y56854, p1228777, b123456, u000000
  static String _generateReceiptId(String type, String? operationNumber) {
    final prefix = _getTypePrefix(type);
    final number = operationNumber ?? '000000';
    return '$prefix$number';
  }

  /// Obtiene el prefijo de una letra según el tipo
  static String _getTypePrefix(String type) {
    switch (type.toLowerCase()) {
      case 'yape':
        return 'y';
      case 'plin':
        return 'p';
      case 'boleta':
        return 'b';
      default:
        return 'u'; // unknown
    }
  }

  /// Detecta el tipo de comprobante desde la descripción
  static String _detectType(String? description) {
    if (description == null) return 'unknown';
    final lowerDesc = description.toLowerCase();
    if (lowerDesc.contains('yape')) return 'yape';
    if (lowerDesc.contains('plin')) return 'plin';
    if (lowerDesc.contains('boleta')) return 'boleta';
    return 'unknown';
  }

  /// Crea un ReceiptRecord desde un Map (usado por SQLite)
  factory ReceiptRecord.fromMap(Map<String, dynamic> map) {
    return ReceiptRecord(
      id: map['id'] as int?,
      receiptId: map['receipt_id'] as String?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      time: map['time'] as String?,
      type: map['type'] as String,
      operationNumber: map['operation_number'] as String?,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convierte el ReceiptRecord a Map (para guardar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_id': receiptId,
      'merchant': merchant,
      'amount': amount,
      'date': date,
      'time': time,
      'type': type,
      'operation_number': operationNumber,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea una copia con campos modificados
  ReceiptRecord copyWith({
    int? id,
    String? receiptId,
    String? merchant,
    double? amount,
    String? date,
    String? time,
    String? type,
    String? operationNumber,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptRecord(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      operationNumber: operationNumber ?? this.operationNumber,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReceiptRecord(id: $id, receiptId: $receiptId, merchant: $merchant, amount: $amount, date: $date, type: $type)';
  }
}
