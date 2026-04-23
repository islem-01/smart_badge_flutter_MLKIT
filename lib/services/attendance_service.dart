// lib/services/attendance_service.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import 'database_service.dart';

enum ScanType { checkIn, checkOut, alreadyScanned }

class ScanResult {
  final ScanType   type;
  final Attendance attendance;
  final Employee   employee;
  final String     message;

  ScanResult({
    required this.type, required this.attendance,
    required this.employee, required this.message,
  });
}

class AttendanceService extends ChangeNotifier {
  final _db   = DatabaseService();
  final _uuid = const Uuid();

  List<Attendance>   _todayAttendance = [];
  Map<String, int>   _todayStats = {'total': 0, 'present': 0, 'absent': 0};

  List<Attendance>   get todayAttendance => _todayAttendance;
  Map<String, int>   get todayStats      => _todayStats;

  Future<void> loadTodayData() async {
    _todayAttendance = await _db.getTodayAttendance();
    _todayStats      = await _db.getTodayStats();
    notifyListeners();
  }

  Future<ScanResult> processScan(Employee emp) async {
    final existing = await _db.getTodayAttendanceForEmployee(emp.id);

    if (existing == null) {
      // Entrée
      final a = Attendance(
        id: _uuid.v4(), employeeId: emp.id,
        employeeName: emp.name, department: emp.department,
        checkIn: DateTime.now(),
        date: DateTime.now().toIso8601String().substring(0, 10),
      );
      await _db.addAttendance(a);
      await loadTodayData();
      return ScanResult(
        type: ScanType.checkIn, attendance: a, employee: emp,
        message: 'Bienvenue ${emp.name} ! Entrée enregistrée.',
      );
    } else if (existing.checkOut == null) {
      // Sortie
      final updated = existing.copyWith(checkOut: DateTime.now());
      await _db.updateAttendance(updated);
      await loadTodayData();
      return ScanResult(
        type: ScanType.checkOut, attendance: updated, employee: emp,
        message: 'Au revoir ${emp.name} ! Durée: ${updated.workDurationFormatted}',
      );
    } else {
      // Déjà sorti
      return ScanResult(
        type: ScanType.alreadyScanned, attendance: existing, employee: emp,
        message: '${emp.name} a déjà terminé sa journée.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() =>
      _db.getWeeklyStats();

  Future<List<Attendance>> getEmployeeHistory(String empId) =>
      _db.getEmployeeAttendance(empId);

  Future<List<Attendance>> getByDate(String date) =>
      _db.getAttendanceByDate(date);
}
