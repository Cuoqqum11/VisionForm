import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/daily_workout_summary.dart';

class DatabaseHelper {
  // 1. Singleton Setup
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // 2. Open the Database Connection
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Find the safe directory on the phone to store the data
    String path = join(await getDatabasesPath(), 'visionform_v1.db');

    // Open the database and create the table if it doesn't exist
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workout_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT, 
            score REAL,
            reps INTEGER
          )
        ''');
      },
    );
  }

  // ==========================================
  // CORE FUNCTIONS
  // ==========================================

  // 3. Save a completed workout (Call this when the user hits "Stop Tracking")
  Future<void> insertWorkoutSession({required double finalScore, required int totalReps}) async {
    final db = await database;
    
    await db.insert(
      'workout_sessions',
      {
        // Save the exact current time in ISO8601 string format
        'created_at': DateTime.now().toIso8601String(), 
        'score': finalScore,
        'reps': totalReps,
      },
      // If by some miracle an ID conflicts, replace it safely
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 4. Feed the Yearly Progress Chart
  Future<List<DailyWorkoutSummary>> getYearlyChartData() async {
    final db = await database;

    // Use SQLite's native DATE() function to strip the time off created_at.
    // This allows us to group multiple workouts done on the same day together!
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        DATE(created_at) as workout_date, 
        AVG(score) as avg_score, 
        SUM(reps) as total_reps 
      FROM workout_sessions 
      WHERE created_at >= date('now', '-1 year')
      GROUP BY DATE(created_at)
      ORDER BY workout_date ASC
    ''');

    // Convert the raw SQL maps into your clean Dart model
    return maps.map((map) {
      return DailyWorkoutSummary(
        date: DateTime.parse(map['workout_date']),
        averageScore: map['avg_score']?.toDouble() ?? 0.0,
        totalReps: map['total_reps']?.toInt() ?? 0,
      );
    }).toList();
  }
}