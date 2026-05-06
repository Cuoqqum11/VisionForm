import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_model.dart';
import '../models/workout_record_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      duration INTEGER NOT NULL,
      description TEXT NOT NULL,
      instruction TEXT NOT NULL,
      imageUrl TEXT NOT NULL
)''');

    await db.execute('''
      CREATE TABLE workout_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      workoutId INTEGER NOT NULL,
      date TEXT NOT NULL,
      timeStamp INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      reps INTEGER NOT NULL,
      sets INTEGER NOT NULL,
      notes TEXT NOT NULL,
      FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
)''');
  }

  Future<void> insertWorkout(Workout workout) async {
    final db = await DatabaseService.instance.database;
    await db.insert(
      'workouts',
      workout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertWorkoutRecord(WorkoutRecord workoutRecord) async {
    final db = await instance.database;
    await db.insert(
      'workout_records',
      workoutRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Workout>> getWorkout() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('workouts');
    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  Future<List<WorkoutRecord>> getWorkoutRecords(int workoutId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_records',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
      orderBy: 'timeStamp DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  Future<int> getWorkoutCount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM workouts'),
    );
    return count ?? 0;
  }
}
