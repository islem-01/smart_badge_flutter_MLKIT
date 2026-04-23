// lib/models/employee_model.dart

class Employee {
  final String id;
  final String name;
  final String department;
  final String email;
  final String role; // 'admin' ou 'employee'
  final String? photoUrl;
  final String qrCode;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.email,
    required this.role,
    this.photoUrl,
    required this.qrCode,
    required this.createdAt,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id:         map['id'] ?? '',
      name:       map['name'] ?? '',
      department: map['department'] ?? '',
      email:      map['email'] ?? '',
      role:       map['role'] ?? 'employee',
      photoUrl:   map['photoUrl'],
      qrCode:     map['qrCode'] ?? '',
      createdAt:  map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':         id,
    'name':       name,
    'department': department,
    'email':      email,
    'role':       role,
    'photoUrl':   photoUrl,
    'qrCode':     qrCode,
    'createdAt':  createdAt.toIso8601String(),
  };

  Employee copyWith({
    String? id, String? name, String? department,
    String? email, String? role, String? photoUrl,
    String? qrCode, DateTime? createdAt,
  }) => Employee(
    id:         id         ?? this.id,
    name:       name       ?? this.name,
    department: department ?? this.department,
    email:      email      ?? this.email,
    role:       role       ?? this.role,
    photoUrl:   photoUrl   ?? this.photoUrl,
    qrCode:     qrCode     ?? this.qrCode,
    createdAt:  createdAt  ?? this.createdAt,
  );

  // Couleur selon département
  int get deptColor {
    switch (department) {
      case 'Informatique':        return 0xFF1E3A8A;
      case 'Ressources Humaines': return 0xFF7C3AED;
      case 'Finance':             return 0xFF059669;
      case 'Marketing':           return 0xFFD97706;
      case 'Direction':           return 0xFF0891B2;
      case 'Commercial':          return 0xFFDC2626;
      default:                    return 0xFF6B7280;
    }
  }
}
