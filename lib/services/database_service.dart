import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:receipt_parser/receipt_parser.dart';

/// Servicio para gestionar la base de datos SQLite local de comprobantes.
/// Implementa patrón Singleton para una única instancia de la BD.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// Obtiene la instancia de la base de datos, creándola si no existe.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos y crea las tablas necesarias.
  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, 'resilex.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Crea la tabla de receipts y sus índices.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        time TEXT,
        type TEXT NOT NULL,
        operation_number TEXT,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Índices para optimizar queries
    await db.execute('CREATE INDEX idx_date ON receipts(date DESC)');
    await db.execute('CREATE INDEX idx_type ON receipts(type)');
    await db.execute(
      'CREATE INDEX idx_created_at ON receipts(created_at DESC)',
    );
  }

  /// Inserta un nuevo comprobante en la base de datos.
  /// Retorna el ID del comprobante insertado, o -1 si ya existe (duplicado).
  Future<int> insertReceipt(ReceiptData receipt) async {
    final Database db = await database;

    // Validar duplicados por número de operación
    if (receipt.operationNumber != null &&
        receipt.operationNumber!.isNotEmpty) {
      final existing = await _getReceiptByOperationNumber(
        receipt.operationNumber!,
      );

      if (existing != null) {
        // Ya existe - retornar -1 para indicar duplicado
        return -1;
      }
    }

    // No es duplicado - insertar normalmente
    return await db.insert('receipts', {
      'merchant': receipt.merchant,
      'amount': receipt.amount,
      'date': receipt.date,
      'time': receipt.time,
      'type': _getReceiptType(receipt.description ?? 'unknown'),
      'operation_number': receipt.operationNumber,
      'description': receipt.description,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Busca un comprobante por número de operación.
  Future<Map<String, dynamic>?> _getReceiptByOperationNumber(
    String operationNumber,
  ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'receipts',
      where: 'operation_number = ?',
      whereArgs: [operationNumber],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Obtiene todos los comprobantes ordenados por fecha descendente.
  Future<List<ReceiptData>> getAllReceipts() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return ReceiptData(
        merchant: maps[i]['merchant'] as String,
        amount: maps[i]['amount'] as double,
        date: maps[i]['date'] as String,
        time: maps[i]['time'] as String?,
        operationNumber: maps[i]['operation_number'] as String?,
        description: maps[i]['description'] as String?,
      );
    });
  }

  /// Obtiene comprobantes de un mes específico (formato: "MM/YYYY" ej: "08/2025").
  Future<List<ReceiptData>> getReceiptsByMonth(String month) async {
    final Database db = await database;

    // Extraer mes y año del formato "08/2025"
    final parts = month.split('/');
    if (parts.length != 2) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where:
          "strftime('%m/%Y', substr(date, 7, 4) || '-' || substr(date, 4, 2) || '-' || substr(date, 1, 2)) = ?",
      whereArgs: [month],
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return ReceiptData(
        merchant: maps[i]['merchant'] as String,
        amount: maps[i]['amount'] as double,
        date: maps[i]['date'] as String,
        time: maps[i]['time'] as String?,
        operationNumber: maps[i]['operation_number'] as String?,
        description: maps[i]['description'] as String?,
      );
    });
  }

  /// Obtiene comprobantes en un rango de fechas (formato: "DD/MM/YYYY").
  Future<List<ReceiptData>> getReceiptsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return ReceiptData(
        merchant: maps[i]['merchant'] as String,
        amount: maps[i]['amount'] as double,
        date: maps[i]['date'] as String,
        time: maps[i]['time'] as String?,
        operationNumber: maps[i]['operation_number'] as String?,
        description: maps[i]['description'] as String?,
      );
    });
  }

  /// Actualiza un comprobante existente.
  Future<int> updateReceipt(int id, ReceiptData receipt) async {
    final Database db = await database;

    return await db.update(
      'receipts',
      {
        'merchant': receipt.merchant,
        'amount': receipt.amount,
        'date': receipt.date,
        'time': receipt.time,
        'operation_number': receipt.operationNumber,
        'description': receipt.description,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un comprobante por su ID.
  Future<int> deleteReceipt(int id) async {
    final Database db = await database;

    return await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina todos los comprobantes (útil para testing).
  Future<int> deleteAllReceipts() async {
    final Database db = await database;
    return await db.delete('receipts');
  }

  /// Obtiene el conteo total de comprobantes.
  Future<int> getReceiptsCount() async {
    final Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM receipts');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Extrae el tipo de comprobante desde la descripción.
  String _getReceiptType(String description) {
    final String lowerDesc = description.toLowerCase();

    if (lowerDesc.contains('yape')) return 'yape';
    if (lowerDesc.contains('plin')) return 'plin';
    if (lowerDesc.contains('boleta')) return 'boleta';

    return 'unknown';
  }

  /// Cierra la conexión de la base de datos.
  Future<void> close() async {
    final Database db = await database;
    await db.close();
  }
}
