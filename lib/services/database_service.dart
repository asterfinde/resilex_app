import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt_record.dart';

/// Servicio para gestionar la base de datos SQLite local de comprobantes.
/// Implementa patrón Singleton para una única instancia de la BD.
///
/// NOTA: Esta BD es INDEPENDIENTE de la BD de NativeStateManager (user_state.db)
/// - resilex.db: Almacena comprobantes/tickets procesados
/// - user_state.db: Almacena sesión de usuario (para instant restoration)
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
        receipt_id TEXT NOT NULL UNIQUE,
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
    await db.execute('CREATE INDEX idx_receipt_id ON receipts(receipt_id)');
    await db.execute('CREATE INDEX idx_date ON receipts(date DESC)');
    await db.execute('CREATE INDEX idx_type ON receipts(type)');
    await db.execute(
      'CREATE INDEX idx_created_at ON receipts(created_at DESC)',
    );
  }

  /// Inserta un nuevo comprobante en la base de datos.
  /// Retorna el ID del comprobante insertado, o -1 si ya existe (duplicado).
  Future<int> insertReceipt(ReceiptRecord receipt) async {
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
      'receipt_id': receipt.receiptId,
      'merchant': receipt.merchant,
      'amount': receipt.amount,
      'date': receipt.date,
      'time': receipt.time,
      'type': receipt.type,
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
  /// Optimizado: usa created_at (que tiene índice) en lugar de date (texto)
  Future<List<ReceiptRecord>> getAllReceipts() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      orderBy: 'created_at DESC', // Usa índice idx_created_at
    );

    return List.generate(maps.length, (i) => ReceiptRecord.fromMap(maps[i]));
  }

  /// Obtiene la lista de meses disponibles en la BD (formato: "MM/YYYY").
  /// Ordenados del más reciente al más antiguo.
  Future<List<String>> getAvailableMonths() async {
    final Database db = await database;

    // Extraer mes y año únicos de la fecha
    // SQLite no tiene tipo fecha nativo, usamos strftime sobre el string
    // Asumimos formato dd/MM/yyyy en la columna date
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT 
        strftime('%m/%Y', substr(date, 7, 4) || '-' || substr(date, 4, 2) || '-' || substr(date, 1, 2)) as month_year,
        substr(date, 7, 4) || substr(date, 4, 2) as sort_key
      FROM receipts 
      ORDER BY sort_key DESC
    ''');

    return maps
        .map((m) => m['month_year'] as String?)
        .where((m) => m != null)
        .cast<String>()
        .toList();
  }

  /// Obtiene comprobantes de un mes específico (formato: "MM/YYYY" ej: "08/2025").
  Future<List<ReceiptRecord>> getReceiptsByMonth(String month) async {
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

    return List.generate(maps.length, (i) => ReceiptRecord.fromMap(maps[i]));
  }

  /// Obtiene comprobantes en un rango de fechas (formato: "DD/MM/YYYY").
  Future<List<ReceiptRecord>> getReceiptsByDateRange(
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

    return List.generate(maps.length, (i) => ReceiptRecord.fromMap(maps[i]));
  }

  /// Actualiza un comprobante existente.
  Future<int> updateReceipt(int id, ReceiptRecord receipt) async {
    final Database db = await database;

    return await db.update(
      'receipts',
      {
        'receipt_id': receipt.receiptId,
        'merchant': receipt.merchant,
        'amount': receipt.amount,
        'date': receipt.date,
        'time': receipt.time,
        'type': receipt.type,
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

  /// Cierra la conexión de la base de datos.
  Future<void> close() async {
    final Database db = await database;
    await db.close();
  }
}
