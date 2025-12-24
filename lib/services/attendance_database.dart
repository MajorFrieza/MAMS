import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_record.dart';

class AttendanceDatabase {
  static final AttendanceDatabase _instance = AttendanceDatabase._internal();
  static Database? _database;

  factory AttendanceDatabase() {
    return _instance;
  }

  AttendanceDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mams_attendance.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        checkInTime TEXT,
        checkOutTime TEXT,
        status TEXT NOT NULL,
        faceImagePath TEXT,
        location TEXT NOT NULL
      )
    ''');
  }

  // Insert or update attendance record
  Future<int> insertAttendance(AttendanceRecord record) async {
    final db = await database;

    // Check if record for today already exists
    final existing = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [record.dateOnly],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      return await db.update(
        'attendance',
        record.toMap(),
        where: 'date = ?',
        whereArgs: [record.dateOnly],
      );
    } else {
      // Insert new record
      return await db.insert('attendance', record.toMap());
    }
  }

  // Get today's attendance record
  Future<AttendanceRecord?> getTodayAttendance() async {
    final db = await database;
    final today = DateTime.now();
    final dateOnly =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final result = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [dateOnly],
    );

    if (result.isNotEmpty) {
      return AttendanceRecord.fromMap(result.first);
    }
    return null;
  }

  // Get all attendance records
  Future<List<AttendanceRecord>> getAllAttendance() async {
    final db = await database;
    final result = await db.query('attendance', orderBy: 'date DESC');
    return result.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  // Get attendance records for date range
  Future<List<AttendanceRecord>> getAttendanceRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final start =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final end =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    final result = await db.query(
      'attendance',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return result.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  // Delete attendance record
  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  // Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
