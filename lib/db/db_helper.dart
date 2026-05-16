import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trasanctions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        date TEXT,
        montant REAL,
        description TEXT
      )
    ''');
  }

  Future<int> insertOperation(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trasanctions', row);
  }

  Future<List<Map<String, dynamic>>> getAllTrasanctions() async {
    final db = await instance.database;
    return await db.query('trasanctions');
  }

  Future<int> updateOperation(Map<String, dynamic> row, int id) async {
    final db = await instance.database;
    return await db.update(
      'trasanctions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOperation(int id) async {
    final db = await instance.database;
    return await db.delete('trasanctions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllOperations() async {
    final db = await database;
    return await db.delete('trasanctions');
  }

  Future<double> getTotalRevenus() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(montant) as total FROM trasanctions WHERE type='Entrant'",
    );
    return result.first['total'] != null
        ? result.first['total'] as double
        : 0.0;
  }

  Future<double> getRevenus() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(montant) as total FROM trasanctions WHERE type='Entrant'",
    );
    return result.first['total'] != null
        ? result.first['total'] as double
        : 0.0;
  }

  Future<double> getTotalDepenses() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(montant) as total FROM trasanctions WHERE type='Sortant'",
    );
    return result.first['total'] != null
        ? result.first['total'] as double
        : 0.0;
  }

  Future<double> getSoldePrincipal() async {
    double revenus = await getTotalRevenus();
    double depenses = await getTotalDepenses();
    return revenus - depenses;
  }
}
