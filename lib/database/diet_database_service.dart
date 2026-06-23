import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diet_models.dart';
 
class DietDatabaseService {
  static final DietDatabaseService instance = DietDatabaseService._init();
  static Database? _database;
  DietDatabaseService._init();
 
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diet.db');
    return _database!;
  }
 
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }
 
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diet_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mealName TEXT NOT NULL,
        tag TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        carbs INTEGER NOT NULL,
        fat INTEGER NOT NULL,
        loggedAtMillis INTEGER NOT NULL
      )''');
  }
 
  /// Helper: today's date as yyyy-MM-dd (local time, no external package needed).
  static String todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }
 
  Future<int> insertLog(DietLogEntry entry) async {
    final db = await instance.database;
    return await db.insert(
      'diet_logs',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
 
  /// All entries logged on a specific yyyy-MM-dd date.
  Future<List<DietLogEntry>> getLogsForDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'diet_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'loggedAtMillis DESC',
    );
    return maps.map((m) => DietLogEntry.fromMap(m)).toList();
  }
 
  /// All entries logged today.
  Future<List<DietLogEntry>> getTodaysLogs() => getLogsForDate(todayKey());
 
  /// Every logged entry, most recent first — useful for a future history screen.
  Future<List<DietLogEntry>> getAllLogs() async {
    final db = await instance.database;
    final maps = await db.query('diet_logs', orderBy: 'loggedAtMillis DESC');
    return maps.map((m) => DietLogEntry.fromMap(m)).toList();
  }
 
  /// Sum of calories/macros for a given date — handy for a dashboard on
  /// the home screen later ("calories eaten today").
  Future<Map<String, int>> getTotalsForDate(String date) async {
    final logs = await getLogsForDate(date);
    int calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final l in logs) {
      calories += l.calories;
      protein += l.protein;
      carbs += l.carbs;
      fat += l.fat;
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
 
  Future<Map<String, int>> getTodaysTotals() => getTotalsForDate(todayKey());
 
  Future<void> deleteLog(int id) async {
    final db = await instance.database;
    await db.delete('diet_logs', where: 'id = ?', whereArgs: [id]);
  }
}