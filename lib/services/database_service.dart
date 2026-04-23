// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/employee_model.dart';
import '../models/attendance_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path   = p.join(dbPath, 'smart_badge.db');
    return openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int _) async {
    await db.execute('''
      CREATE TABLE employees (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        department TEXT NOT NULL, email TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'employee',
        photoUrl TEXT, qrCode TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL, employeeName TEXT NOT NULL,
        department TEXT NOT NULL,
        checkIn TEXT NOT NULL, checkOut TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees (id)
      )
    ''');
    await _insertDemoData(db);
  }

  Future<void> _insertDemoData(Database db) async {
    final now = DateTime.now().toIso8601String();
    // Admin
    await db.insert('employees', {
      'id': 'admin_001', 'name': 'Directeur Admin',
      'department': 'Direction', 'email': 'admin@company.com',
      'role': 'admin', 'photoUrl': null,
      'qrCode': 'BADGE_admin_001', 'createdAt': now,
    });
    // Employés démo
    final emps = [
      {'id':'emp_001','name':'Ahmed Ben Ali',     'department':'Informatique',        'email':'ahmed@company.com'},
      {'id':'emp_002','name':'Sara Mansouri',      'department':'Ressources Humaines', 'email':'sara@company.com'},
      {'id':'emp_003','name':'Mohamed Trabelsi',   'department':'Finance',             'email':'mohamed@company.com'},
      {'id':'emp_004','name':'Fatima Khelil',      'department':'Marketing',           'email':'fatima@company.com'},
      {'id':'emp_005','name':'Karim Belhaj',       'department':'Commercial',          'email':'karim@company.com'},
    ];
    for (final e in emps) {
      await db.insert('employees', {
        ...e, 'role': 'employee', 'photoUrl': null,
        'qrCode': 'BADGE_${e['id']}', 'createdAt': now,
      });
    }
  }

  // ── EMPLOYÉS ─────────────────────────────────────────
  Future<List<Employee>> getAllEmployees() async {
    final db   = await database;
    final rows = await db.query('employees', orderBy: 'name ASC');
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> getEmployeeById(String id) async {
    final db   = await database;
    final rows = await db.query('employees', where: 'id=?', whereArgs: [id]);
    return rows.isEmpty ? null : Employee.fromMap(rows.first);
  }

  Future<Employee?> getEmployeeByQR(String qrCode) async {
    final db   = await database;
    final rows = await db.query('employees', where: 'qrCode=?', whereArgs: [qrCode]);
    return rows.isEmpty ? null : Employee.fromMap(rows.first);
  }

  Future<void> addEmployee(Employee e) async {
    final db = await database;
    await db.insert('employees', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEmployee(Employee e) async {
    final db = await database;
    await db.update('employees', e.toMap(), where: 'id=?', whereArgs: [e.id]);
  }

  Future<void> deleteEmployee(String id) async {
    final db = await database;
    await db.delete('employees', where: 'id=?', whereArgs: [id]);
  }

  // ── PRÉSENCES ────────────────────────────────────────
  Future<List<Attendance>> getTodayAttendance() async {
    final db    = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows  = await db.query('attendance',
        where: 'date=?', whereArgs: [today], orderBy: 'checkIn DESC');
    return rows.map(Attendance.fromMap).toList();
  }

  Future<List<Attendance>> getAttendanceByDate(String date) async {
    final db   = await database;
    final rows = await db.query('attendance',
        where: 'date=?', whereArgs: [date], orderBy: 'checkIn DESC');
    return rows.map(Attendance.fromMap).toList();
  }

  Future<List<Attendance>> getEmployeeAttendance(String empId) async {
    final db   = await database;
    final rows = await db.query('attendance',
        where: 'employeeId=?', whereArgs: [empId], orderBy: 'checkIn DESC');
    return rows.map(Attendance.fromMap).toList();
  }

  Future<Attendance?> getTodayAttendanceForEmployee(String empId) async {
    final db    = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows  = await db.query('attendance',
        where: 'employeeId=? AND date=?',
        whereArgs: [empId, today],
        orderBy: 'checkIn DESC', limit: 1);
    return rows.isEmpty ? null : Attendance.fromMap(rows.first);
  }

  Future<void> addAttendance(Attendance a) async {
    final db = await database;
    await db.insert('attendance', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAttendance(Attendance a) async {
    final db = await database;
    await db.update('attendance', a.toMap(), where: 'id=?', whereArgs: [a.id]);
  }

  Future<Map<String, int>> getTodayStats() async {
    final db    = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final total = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM employees WHERE role="employee"')) ?? 0;
    final present = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(DISTINCT employeeId) FROM attendance WHERE date=?',
        [today])) ?? 0;
    return {'total': total, 'present': present, 'absent': total - present};
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db     = await database;
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now()
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      final count = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(DISTINCT employeeId) FROM attendance WHERE date=?',
              [date])) ?? 0;
      result.add({'date': date, 'count': count});
    }
    return result;
  }
}
