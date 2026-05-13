import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/crypto_util.dart';
import '../../models/admin_model.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/attendance_model.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'attendance.db');
    return openDatabase(
      fullPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE admins (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        pin_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Seed default admin (PIN: 2068)
    await db.insert('admins', {
      'id': 'admin',
      'name': 'Admin',
      'pin_hash': CryptoUtil.sha256Hash('2068'),
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        device_id TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE classes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        session_token TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        class_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (class_id) REFERENCES classes(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS admins (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          pin_hash TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.insert(
        'admins',
        {
          'id': 'admin',
          'name': 'Admin',
          'pin_hash': CryptoUtil.sha256Hash('2068'),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ─── Admins ────────────────────────────────────────────────────────────────

  Future<void> insertAdmin(AdminModel admin) async {
    final db = await database;
    await db.insert('admins', admin.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AdminModel?> getAdminById(String id) async {
    final db = await database;
    final rows = await db.query('admins', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AdminModel.fromMap(rows.first);
  }

  Future<List<AdminModel>> getAllAdmins() async {
    final db = await database;
    final rows = await db.query('admins', orderBy: 'created_at ASC');
    return rows.map(AdminModel.fromMap).toList();
  }

  // ─── Users ────────────────────────────────────────────────────────────────

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<List<UserModel>> getUsersByStatus(String status) async {
    final db = await database;
    final rows =
        await db.query('users', where: 'status = ?', whereArgs: [status]);
    return rows.map(UserModel.fromMap).toList();
  }

  Future<void> updateUserStatus(String id, String status) async {
    final db = await database;
    await db.update('users', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateUserDeviceId(String id, String deviceId) async {
    final db = await database;
    await db.update('users', {'device_id': deviceId},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'created_at DESC');
    return rows.map(UserModel.fromMap).toList();
  }

  // ─── Classes ───────────────────────────────────────────────────────────────

  Future<void> insertClass(ClassModel cls) async {
    final db = await database;
    await db.insert('classes', cls.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ClassModel>> getAllClasses() async {
    final db = await database;
    final rows = await db.query('classes', orderBy: 'created_at DESC');
    return rows.map(ClassModel.fromMap).toList();
  }

  Future<ClassModel?> getActiveClass() async {
    final db = await database;
    final rows =
        await db.query('classes', where: 'is_active = 1', limit: 1);
    if (rows.isEmpty) return null;
    return ClassModel.fromMap(rows.first);
  }

  Future<void> setClassActive(String id, {required bool active, String? token}) async {
    final db = await database;
    // Deactivate all first
    await db.update('classes', {'is_active': 0, 'session_token': null});
    if (active) {
      await db.update(
        'classes',
        {'is_active': 1, 'session_token': token},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteClass(String id) async {
    final db = await database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Attendance ────────────────────────────────────────────────────────────

  Future<void> insertAttendance(AttendanceModel record) async {
    final db = await database;
    await db.insert('attendance', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<bool> existsAttendanceForUser(
      String userId, String classId) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'user_id = ? AND class_id = ?',
      whereArgs: [userId, classId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> existsAttendanceForDevice(
      String deviceId, String classId) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'device_id = ? AND class_id = ?',
      whereArgs: [deviceId, classId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<AttendanceModel>> getAttendanceForClass(
      String classId) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    final db = await database;
    final rows =
        await db.query('attendance', orderBy: 'timestamp DESC');
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
