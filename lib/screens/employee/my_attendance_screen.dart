// lib/screens/employee/my_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});
  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  List<Attendance> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final svc  = context.read<AttendanceService>();
    if (auth.currentUser != null) {
      final data = await svc.getEmployeeHistory(auth.currentUser!.id);
      if (mounted) setState(() { _history = data; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon historique'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('Aucun historique',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _history.length,
                    itemBuilder: (_, i) =>
                        _HistoryCard(attendance: _history[i]),
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Attendance attendance;
  const _HistoryCard({required this.attendance});

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  String _month(int m) => const ['','Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'][m];

  @override
  Widget build(BuildContext context) {
    final isToday = attendance.date ==
        DateTime.now().toIso8601String().substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3))
            : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(attendance.date.substring(8, 10),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.black87)),
            Text(_month(int.parse(attendance.date.substring(5, 7))),
                style: TextStyle(fontSize: 10,
                    color: isToday ? Colors.white70 : Colors.grey)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.login, size: 13, color: Colors.green),
              const SizedBox(width: 4),
              Text(_fmt(attendance.checkIn),
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      color: Colors.green)),
              const SizedBox(width: 12),
              const Icon(Icons.logout, size: 13, color: Colors.red),
              const SizedBox(width: 4),
              Text(attendance.checkOut != null
                  ? _fmt(attendance.checkOut!) : '--:--',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: attendance.checkOut != null
                          ? Colors.red : Colors.grey)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(attendance.workDurationFormatted,
                  style: TextStyle(fontSize: 11,
                      color: Colors.grey.shade600)),
            ]),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: attendance.checkOut == null
                ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(attendance.status,
              style: TextStyle(fontSize: 11,
                  color: attendance.checkOut == null
                      ? Colors.green.shade700 : Colors.blue.shade700,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
