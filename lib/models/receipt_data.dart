/// Modelo de datos para un comprobante procesado.
/// Representa la información extraída de un ticket/recibo mediante OCR.
class ReceiptData {
  final int? id; // ID de SQLite (null si no está guardado aún)
  final String merchant; // Comercio/Cliente
  final double amount; // Monto
  final String date; // Fecha en formato "dd/MM/yyyy"
  final String? time; // Hora en formato "HH:mm"
  final String type; // Tipo: "yape", "plin", "boleta", "unknown"
  final String? operationNumber; // Número de operación
  final String? description; // Descripción adicional
  final DateTime? createdAt; // Timestamp de creación
  final DateTime? updatedAt; // Timestamp de actualización

  ReceiptData({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    this.time,
    required this.type,
    this.operationNumber,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un ReceiptData desde un Map (usado por SQLite)
  factory ReceiptData.fromMap(Map<String, dynamic> map) {
    return ReceiptData(
      id: map['id'] as int?,
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

  /// Convierte el ReceiptData a Map (para guardar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
  ReceiptData copyWith({
    int? id,
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
    return ReceiptData(
      id: id ?? this.id,
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
    return 'ReceiptData(id: $id, merchant: $merchant, amount: $amount, date: $date, type: $type)';
  }
}
