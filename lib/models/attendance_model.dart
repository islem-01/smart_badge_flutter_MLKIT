// lib/models/attendance_model.dart

class Attendance {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final DateTime checkIn;
  DateTime? checkOut;
  final String date; // YYYY-MM-DD

  Attendance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.checkIn,
    this.checkOut,
    required this.date,
  });

  Duration? get workDuration {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn);
  }

  String get workDurationFormatted {
    if (workDuration == null) return 'En cours...';
    final h = workDuration!.inHours;
    final m = workDuration!.inMinutes.remainder(60);
    return '${h}h ${m}min';
  }

  String get status => checkOut == null ? 'Présent' : 'Sorti';

  factory Attendance.fromMap(Map<String, dynamic> map) => Attendance(
    id:           map['id'] ?? '',
    employeeId:   map['employeeId'] ?? '',
    employeeName: map['employeeName'] ?? '',
    department:   map['department'] ?? '',
    checkIn:      map['checkIn'] is String
        ? DateTime.parse(map['checkIn'])
        : DateTime.now(),
    checkOut:     map['checkOut'] != null
        ? DateTime.parse(map['checkOut'] as String)
        : null,
    date:         map['date'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id':           id,
    'employeeId':   employeeId,
    'employeeName': employeeName,
    'department':   department,
    'checkIn':      checkIn.toIso8601String(),
    'checkOut':     checkOut?.toIso8601String(),
    'date':         date,
  };

  Attendance copyWith({DateTime? checkOut}) => Attendance(
    id:           id,
    employeeId:   employeeId,
    employeeName: employeeName,
    department:   department,
    checkIn:      checkIn,
    checkOut:     checkOut ?? this.checkOut,
    date:         date,
  );
}
